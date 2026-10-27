/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/musical_key.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/home/bulk_edit/bulk_edit_menu.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Database db;
  late ScoresRepository repo;
  late SetlistsRepository setlistsRepo;
  late List<String> selected;
  late bool deleted;

  Future<void> insertScore(String id) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileType: FileType.pdf,
        fileDownloaded: false,
      ),
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("bulk_edit_menu_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    setlistsRepo = SetlistsRepository(db: db, scoresRepo: repo);
    selected = [];
    deleted = false;
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: repo),
          Provider<SetlistsRepository>.value(value: setlistsRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                BulkEditMenu(
                  selectedScoreIds: selected,
                  onDeleted: () => deleted = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> openMenu(WidgetTester tester, String option) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text(option));
    await settle(tester);
  }

  testWidgets("deleting the selection removes every score", (tester) async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    selected = ["a", "b"];
    await pumpMenu(tester);

    await openMenu(tester, "Delete");

    expect(find.text("Delete 2 scores?"), findsOneWidget);

    await tester.tap(find.text("Yes"));
    // the file cleanup after a delete needs real event loop turns
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await settle(tester);
    }

    expect(await repo.getScore("a"), isNull);
    expect(await repo.getScore("b"), isNull);
    expect(await repo.getScore("c"), isNotNull);
    expect(deleted, isTrue);
  });

  testWidgets("cancelling the confirmation keeps the scores", (tester) async {
    await insertScore("a");
    selected = ["a"];
    await pumpMenu(tester);

    await openMenu(tester, "Delete");
    await tester.tap(find.text("Cancel"));
    await settle(tester);

    expect(await repo.getScore("a"), isNotNull);
    expect(deleted, isFalse);
  });

  testWidgets("the setlist dialog lists rounded tiles", (tester) async {
    await setlistsRepo.createSetlist(name: "Gig");
    await insertScore("a");
    selected = ["a"];
    await pumpMenu(tester);

    await openMenu(tester, "Add to setlist");

    expect(
      find.descendant(
        of: find.byType(SheetopiaDialog),
        matching: find.widgetWithText(RoundedListTile, "Gig"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("adding to a setlist appends the selection", (tester) async {
    final setlist = await setlistsRepo.createSetlist(name: "Gig");
    await insertScore("a");
    await insertScore("b");
    selected = ["a", "b"];
    await pumpMenu(tester);

    await openMenu(tester, "Add to setlist");
    await tester.tap(find.text("Gig"));
    await settle(tester);

    final entries = (await setlistsRepo.getSetlist(setlist.id))!.entries;
    expect(entries.map((e) => e.scoreId), ["a", "b"]);
  });

  testWidgets("a single score is announced in the singular", (tester) async {
    await insertScore("a");
    selected = ["a"];
    await pumpMenu(tester);

    await openMenu(tester, "Delete");

    expect(find.text("Delete 1 score?"), findsOneWidget);
  });

  Future<void> pickField(WidgetTester tester, String field) async {
    await openMenu(tester, "Edit metadata");
    await tester.tap(find.text("Field"));
    await settle(tester);
    await tester.tap(find.text(field).last);
    await settle(tester);
  }

  testWidgets("the metadata dialog sets the arranger of the selection", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    selected = ["a"];
    await pumpMenu(tester);

    await pickField(tester, "Arranger");
    expect(find.text("Edit metadata of 1 score"), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, "Arranger").last,
      "Busoni",
    );
    await settle(tester);
    await tester.tap(find.text("Update"));
    await settle(tester);

    expect((await repo.getScore("a"))!.arranger, "Busoni");
    expect((await repo.getScore("b"))!.arranger, isNull);
  });

  testWidgets("the metadata dialog sets the part of of the selection", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    selected = ["a"];
    await pumpMenu(tester);

    await pickField(tester, "Part of");
    await tester.enterText(
      find.widgetWithText(TextField, "Part of").last,
      "Kinderszenen",
    );
    await settle(tester);
    await tester.tap(find.text("Update"));
    await settle(tester);

    expect((await repo.getScore("a"))!.partOf, "Kinderszenen");
    expect((await repo.getScore("b"))!.partOf, isNull);
  });

  testWidgets("an empty value clears the field", (tester) async {
    await insertScore("a");
    await repo.bulkEditScoreComposer(["a"], "Bach");
    selected = ["a"];
    await pumpMenu(tester);

    await pickField(tester, "Composer");
    await tester.tap(find.text("Clear"));
    await settle(tester);

    expect((await repo.getScore("a"))!.composer, isNull);
  });

  testWidgets("the metadata dialog sets the difficulty", (tester) async {
    await insertScore("a");
    await insertScore("b");
    selected = ["a", "b"];
    await pumpMenu(tester);

    await pickField(tester, "Difficulty");
    await tester.tap(find.byTooltip("Hard"));
    await settle(tester);
    await tester.tap(find.text("Update"));
    await settle(tester);

    expect((await repo.getScore("a"))!.difficulty, Difficulty.hard);
    expect((await repo.getScore("b"))!.difficulty, Difficulty.hard);
  });

  testWidgets("the metadata dialog sets and clears the key", (tester) async {
    await insertScore("a");
    await insertScore("b");
    selected = ["a", "b"];
    await pumpMenu(tester);

    await pickField(tester, "Key");
    await tester.tap(find.byTooltip("Mode"));
    await settle(tester);
    await tester.tap(find.text("Minor").last);
    await settle(tester);
    await tester.tap(find.byTooltip("Tonic"));
    await settle(tester);
    await tester.tap(find.text("F\u266F/G\u266D").last);
    await settle(tester);
    await tester.tap(find.text("Update"));
    await settle(tester);

    const fSharpMinor = MusicalKey("F#", minor: true);
    expect((await repo.getScore("a"))!.musicalKey, fSharpMinor);
    expect((await repo.getScore("b"))!.musicalKey, fSharpMinor);

    await pickField(tester, "Key");
    await tester.tap(find.text("Clear"));
    await settle(tester);

    expect((await repo.getScore("a"))!.musicalKey, null);
  });
}
