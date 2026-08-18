/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/home/library_view.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository repo;
  late LibraryViewModel viewModel;
  late List<String>? selected;
  late bool cleared;

  final timestamp = DateTime.utc(2026, 1, 1);

  Future<void> insertScore(String id, {required String title}) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: title,
        searchText: " ${title.toLowerCase()} ",
        fileDownloaded: false,
        fileType: FileType.pdf,
        lastOpened: Value(timestamp),
        metadataUpdatedAt: Value(timestamp),
        fileUpdatedAt: Value(timestamp),
      ),
    );
  }

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    viewModel = LibraryViewModel(repo: repo);
    selected = null;
    cleared = false;
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    bool selectionMode = false,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: repo),
          Provider<ThumbnailService>.value(value: ThumbnailService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: LibraryView(
              viewModel: viewModel,
              selectionMode: selectionMode,
              onSelectAll: (scoreIds) => selected = scoreIds,
              onClearSelection: () => cleared = true,
            ),
          ),
        ),
      ),
    );
    // the marquees of the cells hold uncancellable delays before they animate
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> pressSelectAll(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets("ctrl+a selects every score, not just the loaded pages", (
    tester,
  ) async {
    for (var i = 0; i < 150; i++) {
      await insertScore("$i", title: "Title ${i.toString().padLeft(3, "0")}");
    }

    await pumpLibrary(tester);
    await pressSelectAll(tester);

    expect(selected, hasLength(150));
  });

  testWidgets("ctrl+a only selects the scores matching the filter", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");
    await insertScore("b", title: "Fugue");

    await pumpLibrary(tester);
    await tester.enterText(find.byType(SearchInput), "sonata");
    await tester.pump(const Duration(seconds: 5));
    await tester.tapAt(const Offset(400, 550));
    await tester.pump(const Duration(seconds: 5));
    await pressSelectAll(tester);

    expect(selected, ["a"]);
  });

  testWidgets("escape clears the selection while in select mode", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");

    await pumpLibrary(tester, selectionMode: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 5));

    expect(cleared, true);
  });

  testWidgets("escape does nothing outside of select mode", (tester) async {
    await insertScore("a", title: "Sonata");

    await pumpLibrary(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 5));

    expect(cleared, false);
  });

  testWidgets("shortcuts survive a trip to another tab of an IndexedStack", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");

    var index = 0;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: repo),
          Provider<ThumbnailService>.value(value: ThumbnailService()),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: IndexedStack(
                index: index,
                children: [
                  LibraryView(
                    viewModel: viewModel,
                    onSelectAll: (scoreIds) => selected = scoreIds,
                  ),
                  const SizedBox.shrink(),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => index = index == 0 ? 1 : 0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(seconds: 5));

    await pressSelectAll(tester);

    expect(selected, ["a"]);
  });

  testWidgets("ctrl+a stays with the search field while it is focused", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");

    await pumpLibrary(tester);
    await tester.enterText(find.byType(SearchInput), "sonata");
    await tester.pump(const Duration(seconds: 5));
    await pressSelectAll(tester);

    expect(selected, null);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(
      field.controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
  });
}
