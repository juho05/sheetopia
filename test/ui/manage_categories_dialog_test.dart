/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/manage_categories_dialog.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<void> createExercise(String name, String category) async {
    final id = await repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(category: Value(category)));
  }

  Future<List<String>> categoryNames() async =>
      (await repo.getAllCategories()).map((c) => c.name).toList();

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = PracticeRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<PracticeRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ManageCategoriesDialog.show(context),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  Future<void> closeDialog(WidgetTester tester) async {
    await tester.tap(find.text("Done"));
    await tester.pumpAndSettle();
  }

  double contentHeight(WidgetTester tester) {
    return tester
        .getSize(
          find
              .descendant(
                of: find.byType(SheetopiaDialog),
                matching: find.byType(Column),
              )
              .first,
        )
        .height;
  }

  testWidgets("an empty list shows a placeholder", (tester) async {
    await pumpDialog(tester);

    expect(find.text("No categories yet."), findsOneWidget);
  });

  testWidgets("the categories are listed with their exercise count", (
    tester,
  ) async {
    final warmup = await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");
    await createExercise("Chromatic", warmup.id);

    await pumpDialog(tester);

    expect(find.text("Warmup"), findsOneWidget);
    expect(find.text("1 exercise"), findsOneWidget);
    expect(find.text("Etudes"), findsOneWidget);
    expect(find.text("No exercises"), findsOneWidget);
  });

  testWidgets("a new category is appended to the list", (tester) async {
    await repo.createCategory("Warmup");

    await pumpDialog(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, "Create"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "Etudes");
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Create"));
    await tester.pumpAndSettle();

    expect(await categoryNames(), ["Warmup", "Etudes"]);
    expect(find.text("Etudes"), findsOneWidget);
  });

  testWidgets("an existing name cannot be used twice", (tester) async {
    await repo.createCategory("Warmup");

    await pumpDialog(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, "Create"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "warmup");
    await tester.pumpAndSettle();

    expect(find.text("This category already exists"), findsOneWidget);
    final create = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Create"),
    );
    expect(create.onPressed, isNull);
  });

  testWidgets("a category can be renamed", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpDialog(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Rename"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "Warm up");
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Rename"));
    await tester.pumpAndSettle();

    expect(await categoryNames(), ["Warm up"]);
    expect((await repo.getAllCategories()).single.id, warmup.id);
  });

  testWidgets("deleting a category warns about its exercises", (tester) async {
    final warmup = await repo.createCategory("Warmup");
    await createExercise("Chromatic", warmup.id);

    await pumpDialog(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();

    expect(
      find.text("1 exercise will no longer have a category."),
      findsOneWidget,
    );

    await tester.tap(find.text("Yes"));
    await tester.pumpAndSettle();

    expect(await categoryNames(), isEmpty);
    expect(find.text("No categories yet."), findsOneWidget);
  });

  testWidgets("dragging a category writes the new order", (tester) async {
    await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");

    await pumpDialog(tester);
    final handle = find.byIcon(Icons.drag_handle).last;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(await categoryNames(), ["Etudes", "Warmup"]);
  });

  testWidgets("a long press anywhere on the tile starts a drag", (
    tester,
  ) async {
    await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");

    await pumpDialog(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text("Etudes")),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(await categoryNames(), ["Etudes", "Warmup"]);
  });

  testWidgets("changes made elsewhere reach the open dialog", (tester) async {
    final warmup = await repo.createCategory("Warmup");

    await pumpDialog(tester);

    final etudes = await repo.createCategory("Etudes");
    await tester.pumpAndSettle();
    expect(find.text("Etudes"), findsOneWidget);

    await repo.renameCategory(etudes.id, "Studies");
    await tester.pumpAndSettle();
    expect(find.text("Studies"), findsOneWidget);

    await createExercise("Chromatic", warmup.id);
    await tester.pumpAndSettle();
    expect(find.text("1 exercise"), findsOneWidget);

    await repo.deleteCategory(etudes.id);
    await tester.pumpAndSettle();
    expect(find.text("Studies"), findsNothing);
  });

  testWidgets("the dialog only takes the height the list needs", (
    tester,
  ) async {
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    await pumpDialog(tester);
    final empty = contentHeight(tester);
    await closeDialog(tester);

    await repo.createCategory("Warmup");
    await pumpDialog(tester);
    final one = contentHeight(tester);
    await closeDialog(tester);

    for (var i = 0; i < 20; i++) {
      await repo.createCategory("Category $i");
    }
    await pumpDialog(tester);
    final many = contentHeight(tester);

    expect(empty, lessThan(screen / 2));
    expect(one, lessThanOrEqualTo(empty + RoundedListTile.defaultHeight));
    expect(many, greaterThan(one));
    expect(many, lessThan(screen));
  });
}
