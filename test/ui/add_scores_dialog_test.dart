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
import 'package:sheetopia/ui/home/score_grid_cell.dart';
import 'package:sheetopia/ui/setlists/add_scores_dialog.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository repo;

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
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>?> openDialog(WidgetTester tester) async {
    List<String>? result;
    var opened = false;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: repo),
          Provider<ThumbnailService>.value(value: ThumbnailService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                if (!opened) {
                  opened = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    result = await AddScoresDialog.show(context);
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    // the marquees of the cells hold uncancellable delays before they animate
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    return result;
  }

  testWidgets("ctrl+a picks every filtered score", (tester) async {
    await insertScore("a", title: "Sonata");
    await insertScore("b", title: "Fugue");

    await openDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump(const Duration(seconds: 5));

    expect(find.text("2 selected"), findsOneWidget);
  });

  testWidgets("the select all button toggles the whole filtered result", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");
    await insertScore("b", title: "Fugue");

    await openDialog(tester);
    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text("2 selected"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.deselect));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text("Add scores"), findsOneWidget);
  });

  testWidgets("escape closes the dialog instead of clearing the picks", (
    tester,
  ) async {
    await insertScore("a", title: "Sonata");

    await openDialog(tester);
    await tester.tap(find.byType(ScoreGridCell).first);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text("1 selected"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AddScoresDialog), findsNothing);
  });
}
