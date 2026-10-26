/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/home/filter_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

void main() {
  late Database db;
  late ScoresRepository repo;
  late LibraryViewModel viewModel;

  setUp(() async {
    db = Database(NativeDatabase.memory());
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    viewModel = LibraryViewModel(repo: repo);
  });

  // closing the database hangs once the dialog was open, so it stays open
  tearDown(() {
    viewModel.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Provider<ScoresRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    FilterDialog.show(context, viewModel: viewModel),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    // lets the initial load of the view model finish
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text("open"));
    await settle(tester);
  }

  Future<void> addFilter(WidgetTester tester, String field) async {
    await tester.tap(find.text("Add filter"));
    await settle(tester);
    await tester.tap(find.text(field));
    await settle(tester);
  }

  testWidgets("optional filters are hidden until added", (tester) async {
    await openDialog(tester);

    expect(find.text("Composer"), findsOneWidget);
    expect(find.text("Arranger"), findsNothing);
    expect(find.text("Difficulty"), findsNothing);

    await addFilter(tester, "Arranger");

    expect(find.text("Arranger"), findsOneWidget);
  });

  testWidgets(
    "a difficulty filter is selected by icon and removed with the field",
    (tester) async {
      await openDialog(tester);

      await addFilter(tester, "Difficulty");
      await tester.tap(find.byTooltip("Easy"));
      await tester.tap(find.byTooltip("Hard"));
      await tester.tap(find.byTooltip("No difficulty"));
      await settle(tester);

      expect(viewModel.filterDifficulties, {
        Difficulty.easy,
        Difficulty.hard,
        null,
      });
      expect(find.byType(DifficultySelector), findsOneWidget);
      await tester.tap(find.byTooltip("Remove field"));
      await settle(tester);

      expect(viewModel.filterDifficulties, isEmpty);
      expect(find.text("Difficulty"), findsNothing);
    },
  );

  testWidgets("active optional filters are shown when reopening", (
    tester,
  ) async {
    viewModel.filterArranger = "Busoni";
    await openDialog(tester);

    expect(find.text("Arranger"), findsOneWidget);
    expect(find.text("Busoni"), findsOneWidget);
  });
}
