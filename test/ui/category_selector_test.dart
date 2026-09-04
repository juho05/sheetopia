/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/practice/category_name_dialog.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<List<String>> categoryNames() async =>
      (await repo.getAllCategories()).map((c) => c.name).toList();

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = PracticeRepository(
      db: db,
      scoresRepo: ScoresRepository(
        db: db,
        thumbnailService: ThumbnailService(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  ExerciseCategory? selected;
  var changes = 0;

  Future<void> pumpSelector(
    WidgetTester tester, {
    ExerciseCategory? category,
    String emptyLabel = "No category",
    bool allowCreate = false,
  }) async {
    selected = category;
    changes = 0;
    await tester.pumpWidget(
      Provider<PracticeRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CategorySelector(
                category: selected,
                emptyLabel: emptyLabel,
                allowCreate: allowCreate,
                onChanged: (category) {
                  changes++;
                  setState(() => selected = category);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byType(CategorySelector));
    await tester.pumpAndSettle();
  }

  testWidgets("the field shows the empty label without a category", (
    tester,
  ) async {
    await pumpSelector(tester, emptyLabel: "All categories");

    expect(find.text("All categories"), findsOneWidget);
    expect(find.text("Category"), findsOneWidget);
  });

  testWidgets("the field shows the selected category", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester, category: warmup);

    expect(find.text("Warmup"), findsOneWidget);
  });

  testWidgets("the dialog offers the empty option and every category", (
    tester,
  ) async {
    await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");

    await pumpSelector(tester, emptyLabel: "All categories");
    await openDialog(tester);

    expect(find.text("Select category"), findsOneWidget);
    // once in the field behind the dialog, once as the first option
    expect(find.text("All categories"), findsNWidgets(2));
    expect(find.text("Warmup"), findsOneWidget);
    expect(find.text("Etudes"), findsOneWidget);
  });

  bool rowSelected(WidgetTester tester, String title) => tester
      .widget<RoundedListTile>(find.widgetWithText(RoundedListTile, title))
      .selected;

  testWidgets("the empty option is highlighted without a category", (
    tester,
  ) async {
    await repo.createCategory("Warmup");

    await pumpSelector(tester);
    await openDialog(tester);

    expect(rowSelected(tester, "No category"), isTrue);
    expect(rowSelected(tester, "Warmup"), isFalse);
  });

  testWidgets("the current category is highlighted", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester, category: warmup);
    await openDialog(tester);

    expect(rowSelected(tester, "Warmup"), isTrue);
    expect(rowSelected(tester, "No category"), isFalse);
  });

  testWidgets("picking a category reports it back", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester);
    await openDialog(tester);
    await tester.tap(find.text("Warmup"));
    await tester.pumpAndSettle();

    expect(changes, 1);
    expect(selected?.id, warmup.id);
    expect(find.text("Select category"), findsNothing);
  });

  testWidgets("picking the empty option clears the category", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester, category: warmup);
    await openDialog(tester);
    await tester.tap(find.text("No category"));
    await tester.pumpAndSettle();

    expect(changes, 1);
    expect(selected, isNull);
  });

  testWidgets("cancelling keeps the current category", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester, category: warmup);
    await openDialog(tester);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    expect(changes, 0);
    expect(selected?.id, warmup.id);
  });

  testWidgets("the search narrows the categories down", (tester) async {
    await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");

    await pumpSelector(tester);
    await openDialog(tester);
    await tester.enterText(find.byType(TextField), "tud");
    await tester.pumpAndSettle();

    expect(find.text("Etudes"), findsOneWidget);
    expect(find.text("Warmup"), findsNothing);
    // the empty option is filtered like any other row, only the field keeps it
    expect(find.text("No category"), findsOneWidget);
  });

  testWidgets("the empty option can be searched for", (tester) async {
    await repo.createCategory("Warmup");

    await pumpSelector(tester);
    await openDialog(tester);
    await tester.enterText(find.byType(TextField), "categ");
    await tester.pumpAndSettle();

    expect(find.text("No category"), findsNWidgets(2));
    expect(find.text("Warmup"), findsNothing);
  });

  testWidgets("a search without matches shows a placeholder", (tester) async {
    await repo.createCategory("Warmup");

    await pumpSelector(tester);
    await openDialog(tester);
    await tester.enterText(find.byType(TextField), "scales");
    await tester.pumpAndSettle();

    expect(find.text("No matching categories."), findsOneWidget);
  });

  testWidgets("the selected category is listed above the empty option", (
    tester,
  ) async {
    await repo.createCategory("Etudes");
    final warmup = await repo.createCategory("Warmup");

    await pumpSelector(tester, category: warmup);
    await openDialog(tester);

    final selected = tester.getTopLeft(find.text("Warmup").last).dy;
    final empty = tester.getTopLeft(find.text("No category").last).dy;
    final other = tester.getTopLeft(find.text("Etudes")).dy;
    expect(selected, lessThan(empty));
    expect(empty, lessThan(other));
  });

  testWidgets("creating is only offered when allowed", (tester) async {
    await pumpSelector(tester);
    await openDialog(tester);

    expect(find.byTooltip("Create category"), findsNothing);
  });

  testWidgets("a created category is selected right away", (tester) async {
    await pumpSelector(tester, allowCreate: true);
    await openDialog(tester);
    await tester.enterText(find.byType(TextField), "Warmup");
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Create category"));
    await tester.pumpAndSettle();

    expect(find.text("Create category"), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(CategoryNameDialog),
        matching: find.widgetWithText(FilledButton, "Create"),
      ),
    );
    await tester.pumpAndSettle();

    // the name dialog started off with the search text
    expect(await categoryNames(), ["Warmup"]);
    expect(changes, 1);
    expect(selected?.name, "Warmup");
    expect(find.text("Select category"), findsNothing);
  });
}
