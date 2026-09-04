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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/exercises_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<String> createExercise(String name) => repo.createExercise(
    name: name,
    description: "",
    instrument: "",
    source: "",
    sourceLink: "",
    tagIds: const [],
  );

  Future<void> createExercises(int count) async {
    for (var i = 0; i < count; i++) {
      await createExercise("Exercise $i");
    }
  }

  Future<List<String>> exerciseNames() async =>
      (await repo.getExercises(size: 100)).map((e) => e.name).toList();

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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpExercises(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (context, state) => const ExercisesPage()),
        GoRoute(
          path: "/practice/exercises/:id",
          builder: (context, state) => const Text("exercise page"),
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
    await settle(tester);
  }

  Finder tileOf(String name) => find
      .ancestor(of: find.text(name), matching: find.byType(RoundedListTile))
      .first;

  Future<void> longPressExercise(WidgetTester tester, String name) async {
    await tester.longPress(tileOf(name));
    await settle(tester);
  }

  Future<void> tapExercise(WidgetTester tester, String name) async {
    await tester.tap(tileOf(name));
    await settle(tester);
  }

  Future<void> openBulkMenu(WidgetTester tester, String option) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text(option));
    await settle(tester);
  }

  testWidgets("the bulk menu only shows while selecting", (tester) async {
    await createExercises(2);
    await pumpExercises(tester);

    final appBarMenu = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(MenuButton),
    );
    expect(appBarMenu, findsNothing);

    await longPressExercise(tester, "Exercise 0");

    expect(appBarMenu, findsOneWidget);
  });

  testWidgets("the bulk menu deletes the selected exercises", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await tapExercise(tester, "Exercise 1");

    await openBulkMenu(tester, "Delete");

    expect(find.text("Delete 2 exercises?"), findsOneWidget);

    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(await exerciseNames(), ["Exercise 2"]);
    expect(find.text("Exercises"), findsOneWidget);
  });

  testWidgets("cancelling the confirmation keeps the exercises", (
    tester,
  ) async {
    await createExercises(2);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await openBulkMenu(tester, "Delete");
    await tester.tap(find.text("Cancel"));
    await settle(tester);

    expect(await repo.countExercises(), 2);
    expect(find.text("1 selected"), findsOneWidget);
  });

  testWidgets("the bulk menu moves the selection into a category", (
    tester,
  ) async {
    await repo.createCategory("Warmup");
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await tapExercise(tester, "Exercise 1");

    await openBulkMenu(tester, "Edit category");
    await tester.tap(find.text("Warmup"));
    await settle(tester);

    final exercises = await repo.getExercises(size: 100);
    expect(
      {for (final e in exercises) e.name: e.category?.name},
      {"Exercise 0": "Warmup", "Exercise 1": "Warmup", "Exercise 2": null},
    );
  });

  testWidgets("the bulk category dialog highlights no category", (
    tester,
  ) async {
    await repo.createCategory("Warmup");
    await createExercises(2);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await openBulkMenu(tester, "Edit category");

    final rows = tester.widgetList<RoundedListTile>(
      find.descendant(
        of: find.byType(SheetopiaDialog),
        matching: find.byType(RoundedListTile),
      ),
    );
    expect(rows, hasLength(2));
    expect(rows.every((row) => !row.selected), isTrue);
  });

  testWidgets("the bulk menu adds the selection to a routine", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await tapExercise(tester, "Exercise 2");

    await openBulkMenu(tester, "Add to routine");
    await tester.tap(find.text("Morning"));
    await settle(tester);

    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.map((e) => e.exercise.name), [
      "Exercise 0",
      "Exercise 2",
    ]);
  });

  testWidgets("a tile adds a single exercise to a routine", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    await createExercises(2);
    await pumpExercises(tester);

    await tester.tap(
      find.descendant(
        of: tileOf("Exercise 1"),
        matching: find.byType(MenuButton),
      ),
    );
    await settle(tester);
    await tester.tap(find.text("Add to routine"));
    await settle(tester);
    await tester.tap(find.text("Morning"));
    await settle(tester);

    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.map((e) => e.exercise.name), ["Exercise 1"]);
  });

  testWidgets("the routine dialog lists rounded tiles", (tester) async {
    await repo.createRoutine(name: "Morning", description: "");
    await createExercises(1);
    await pumpExercises(tester);

    await tester.tap(
      find.descendant(
        of: tileOf("Exercise 0"),
        matching: find.byType(MenuButton),
      ),
    );
    await settle(tester);
    await tester.tap(find.text("Add to routine"));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byType(SheetopiaDialog),
        matching: find.widgetWithText(RoundedListTile, "Morning"),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a tile deletes a single exercise from its menu", (tester) async {
    await createExercises(2);
    await pumpExercises(tester);

    await tester.tap(
      find.descendant(
        of: tileOf("Exercise 0"),
        matching: find.byType(MenuButton),
      ),
    );
    await settle(tester);
    await tester.tap(find.text("Delete"));
    await settle(tester);
    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(await exerciseNames(), ["Exercise 1"]);
  });
}
