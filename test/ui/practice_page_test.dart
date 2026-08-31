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
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/practice/create_practice_routine_page.dart';
import 'package:sheetopia/ui/practice/practice_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<String> createExercise(String name, {String instrument = ""}) =>
      repo.createExercise(
        name: name,
        description: "",
        instrument: instrument,
        source: "",
        sourceLink: "",
        tagIds: const [],
      );

  Future<String> createRoutine(
    String name, {
    List<String> exercises = const [],
    Duration? targetDuration,
  }) async {
    final id = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: id, name: name),
    );
    for (final (position, exercise) in exercises.indexed) {
      await db.managers.practiceRoutineEntriesTable.create(
        (o) => o(
          id: db.newId(),
          routine: id,
          exercise: exercise,
          position: position,
          targetDuration: Value(targetDuration),
        ),
      );
    }
    return id;
  }

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

  Future<void> pumpPractice(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: PracticePage())),
        ),
        GoRoute(
          path: "/practice/exercises",
          builder: (context, state) => const Text("exercises page"),
        ),
        GoRoute(
          path: "/practice/routines/create",
          builder: (context, state) => const CreatePracticeRoutinePage(),
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

  testWidgets("an empty library offers to create a routine", (tester) async {
    await pumpPractice(tester);

    expect(find.text("No routines yet."), findsOneWidget);
    expect(find.text("Create routine"), findsOneWidget);
    expect(find.text("0 routines"), findsNothing);
  });

  testWidgets("the placeholder button opens the create page", (tester) async {
    await pumpPractice(tester);

    await tester.tap(find.text("Create routine"));
    await tester.pumpAndSettle();

    expect(find.byType(CreatePracticeRoutinePage), findsOneWidget);
  });

  testWidgets("the exercises card opens the exercises page", (tester) async {
    await pumpPractice(tester);

    await tester.tap(find.text("Exercises"));
    await tester.pumpAndSettle();

    expect(find.text("exercises page"), findsOneWidget);
  });

  testWidgets("routines are listed with their count", (tester) async {
    final exercise = await createExercise("Chromatic");
    await createRoutine(
      "Morning",
      exercises: [exercise],
      targetDuration: const Duration(minutes: 20),
    );
    await createRoutine("Evening");

    await pumpPractice(tester);

    expect(find.text("2 routines"), findsOneWidget);
    expect(find.text("Morning"), findsOneWidget);
    expect(find.text("1 exercise - 20min"), findsOneWidget);
    expect(find.text("0 exercises"), findsOneWidget);
  });

  testWidgets("a search without matches shows a placeholder", (tester) async {
    await createRoutine("Morning");

    await pumpPractice(tester);
    await tester.enterText(find.byType(TextField).first, "evening");
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text("No matching routines."), findsOneWidget);
    expect(find.text("Create routine"), findsNothing);
    expect(find.text("0 of 1"), findsOneWidget);
  });

  testWidgets("the instrument filter narrows the list down", (tester) async {
    final guitar = await createExercise("Chromatic", instrument: "Guitar");
    await createRoutine("Morning", exercises: [guitar]);
    await createRoutine("Evening");

    await pumpPractice(tester);
    await tester.tap(find.byType(FilterButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, "Instrument"),
      "Guitar",
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Done"));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text("Morning"), findsOneWidget);
    expect(find.text("Evening"), findsNothing);
    expect(find.text("1 of 2"), findsOneWidget);
  });
}
