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
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';
import 'package:sheetopia/ui/practice/exercises_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<void> createExercise(String name, {String? category}) async {
    await repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
      categoryId: category,
    );
  }

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = PracticeRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpExercises(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (context, state) => const ExercisesPage()),
        GoRoute(
          path: "/practice/exercises/create",
          builder: (context, state) => const Text("create exercise page"),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<PracticeRepository>.value(
        value: repo,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets("an empty library offers to create an exercise", (tester) async {
    await pumpExercises(tester);

    expect(find.text("No exercises yet."), findsOneWidget);
    expect(find.text("Create exercise"), findsOneWidget);
    expect(find.text("0 exercises"), findsNothing);
  });

  testWidgets("the placeholder button opens the create page", (tester) async {
    await pumpExercises(tester);

    await tester.tap(find.text("Create exercise"));
    await tester.pumpAndSettle();

    expect(find.text("create exercise page"), findsOneWidget);
  });

  testWidgets("the exercises are listed with their count", (tester) async {
    await createExercise("Bends");
    await createExercise("Chromatic");

    await pumpExercises(tester);

    expect(find.text("2 exercises"), findsOneWidget);
    expect(find.text("No exercises yet."), findsNothing);
    expect(find.text("Bends"), findsOneWidget);
    expect(find.text("Chromatic"), findsOneWidget);
  });

  testWidgets("a single exercise is counted in singular", (tester) async {
    await createExercise("Bends");

    await pumpExercises(tester);

    expect(find.text("1 exercise"), findsOneWidget);
  });

  testWidgets("a search without matches shows a placeholder", (tester) async {
    await createExercise("Bends");

    await pumpExercises(tester);
    await tester.enterText(find.byType(TextField).first, "slides");
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text("No matching exercises."), findsOneWidget);
    expect(find.text("Create exercise"), findsNothing);
    expect(find.text("0 of 1"), findsOneWidget);
  });

  testWidgets("the category filter narrows the list down", (tester) async {
    final warmup = await repo.createCategory("Warmup");
    await createExercise("Bends", category: warmup.id);
    await createExercise("Chromatic");

    await pumpExercises(tester);
    await tester.tap(find.byType(FilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CategorySelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Warmup").last);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Done"));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text("Bends"), findsOneWidget);
    expect(find.text("Chromatic"), findsNothing);
    expect(find.text("1 of 2"), findsOneWidget);
  });
}
