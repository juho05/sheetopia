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
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/exercise_card.dart';
import 'package:sheetopia/ui/practice/practice_overlay.dart';
import 'package:sheetopia/ui/practice/practice_stopwatch.dart';
import 'package:sheetopia/ui/practice/routine_play_page.dart';

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
  late ScoresRepository scoresRepo;
  late PracticeRepository repo;

  Future<String> createExercise(String name, {String description = ""}) =>
      repo.createExercise(
        name: name,
        description: description,
        instrument: "",
        source: "",
        sourceLink: "",
        tagIds: const [],
      );

  Future<String> createRoutine(String name, List<String> exerciseIds) async {
    final exercises = await repo.getExercisesById(exerciseIds);
    return repo.createRoutine(
      name: name,
      description: "",
      entries: [
        for (final exerciseId in exerciseIds)
          PracticeRoutineEntry(
            id: repo.newRoutineEntryId(),
            exercise: exercises[exerciseId]!,
          ),
      ],
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("routine_play_page_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = PracticeRepository(
      db: db,
      scoresRepo: scoresRepo,
      minRecordDuration: Duration.zero,
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpPage(WidgetTester tester, String routineId) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PracticeRepository>.value(value: repo),
          Provider<ScoresRepository>.value(value: scoresRepo),
        ],
        child: MaterialApp(home: RoutinePlayPage(routineId: routineId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inOverlay(Finder finder) =>
      find.descendant(of: find.byType(ExerciseStartOverlay), matching: finder);

  Future<void> startExercise(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, "Start"));
    await tester.pumpAndSettle();
  }

  testWidgets("exercises without scores are played as cards", (tester) async {
    final first = await createExercise("Chromatic", description: "Slowly.");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await startExercise(tester);

    expect(find.byType(ExerciseCard), findsOneWidget);
    expect(find.text("Morning"), findsOneWidget);
    expect(find.text("Chromatic"), findsOneWidget);
    expect(find.text("Slowly."), findsOneWidget);
    expect(find.text("1 of 2"), findsOneWidget);
  });

  testWidgets("the toolbar walks through the routine", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await startExercise(tester);

    final previous = find.widgetWithText(OutlinedButton, "Prev");
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, "Next"));
    await tester.pumpAndSettle();
    await startExercise(tester);

    expect(find.text("Long tones"), findsOneWidget);
    expect(find.text("2 of 2"), findsOneWidget);
    // the last exercise finishes the routine instead of moving on
    expect(find.widgetWithText(FilledButton, "Done"), findsOneWidget);

    await tester.tap(previous);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Resume"));
    await tester.pumpAndSettle();

    expect(find.text("Chromatic"), findsOneWidget);
    expect(find.text("1 of 2"), findsOneWidget);
  });

  testWidgets("the sheet jumps to another exercise", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await startExercise(tester);
    await tester.tap(find.text("1 of 2"));
    await tester.pumpAndSettle();

    expect(find.text("Long tones"), findsOneWidget);
    await tester.tap(find.text("Long tones"));
    await tester.pumpAndSettle();
    await startExercise(tester);

    expect(find.text("2 of 2"), findsOneWidget);
    expect(find.byType(ExerciseCard), findsOneWidget);
  });

  testWidgets("an empty routine says so", (tester) async {
    final routineId = await createRoutine("Morning", []);

    await pumpPage(tester, routineId);

    expect(find.text("This routine has no exercises."), findsOneWidget);
  });

  testWidgets("the start dialog introduces the exercise", (tester) async {
    final first = await createExercise("Chromatic", description: "Slowly.");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);

    expect(find.text("Exercise 1 of 2"), findsOneWidget);
    expect(inOverlay(find.text("Chromatic")), findsOneWidget);
    expect(inOverlay(find.text("Slowly.")), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Start"), findsOneWidget);
    expect(
      inOverlay(find.widgetWithText(OutlinedButton, "Next")),
      findsOneWidget,
      reason: "a routine can be walked through from the dialog",
    );
    expect(find.byType(PracticeStopwatch), findsNothing);

    await startExercise(tester);

    expect(find.widgetWithText(FilledButton, "Start"), findsNothing);
    expect(find.byType(PracticeStopwatch), findsOneWidget);
  });

  testWidgets("the stopwatch can be paused and resumed", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await createRoutine("Morning", [exerciseId]);

    await pumpPage(tester, routineId);
    await startExercise(tester);

    final stopwatch = find.byType(PracticeStopwatch);
    expect(tester.widget<PracticeStopwatch>(stopwatch).running, isTrue);

    await tester.tap(find.byTooltip("Pause"));
    await tester.pumpAndSettle();
    expect(tester.widget<PracticeStopwatch>(stopwatch).running, isFalse);
    expect(
      (await db.managers.practiceRecordsTable.get()).single.runningSince,
      isNull,
      reason: "a pause is written through, a kill loses nothing",
    );

    await tester.tap(find.byTooltip("Resume"));
    await tester.pumpAndSettle();
    expect(tester.widget<PracticeStopwatch>(stopwatch).running, isTrue);
  });

  testWidgets("moving on ends the exercise before", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await startExercise(tester);
    await tester.tap(find.widgetWithText(FilledButton, "Next"));
    await tester.pumpAndSettle();

    final entries = await db.managers.practiceRecordsTable.get();
    expect(entries, hasLength(1));
    expect(entries.single.exercise, first);
    expect(entries.single.runningSince, isNull);
    expect(
      find.widgetWithText(FilledButton, "Start"),
      findsOneWidget,
      reason: "the next exercise waits to be started",
    );
  });

  testWidgets("returning to an exercise asks again", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await startExercise(tester);
    await tester.tap(find.widgetWithText(FilledButton, "Next"));
    await tester.pumpAndSettle();
    await tester.tap(inOverlay(find.widgetWithText(OutlinedButton, "Prev")));
    await tester.pumpAndSettle();

    expect(inOverlay(find.text("Chromatic")), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, "Resume"),
      findsOneWidget,
      reason: "the exercise was practiced in this session before",
    );
  });
}
