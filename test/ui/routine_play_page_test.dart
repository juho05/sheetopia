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
import 'package:flutter/material.dart';
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
    repo = PracticeRepository(db: db, scoresRepo: scoresRepo);
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

  testWidgets("exercises without scores are played as cards", (tester) async {
    final first = await createExercise("Chromatic", description: "Slowly.");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);

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

    final previous = find.widgetWithText(OutlinedButton, "Prev");
    expect(tester.widget<OutlinedButton>(previous).onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, "Next"));
    await tester.pumpAndSettle();

    expect(find.text("Long tones"), findsOneWidget);
    expect(find.text("2 of 2"), findsOneWidget);
    // the last exercise finishes the routine instead of moving on
    expect(find.widgetWithText(FilledButton, "Done"), findsOneWidget);

    await tester.tap(previous);
    await tester.pumpAndSettle();

    expect(find.text("Chromatic"), findsOneWidget);
    expect(find.text("1 of 2"), findsOneWidget);
  });

  testWidgets("the sheet jumps to another exercise", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await createRoutine("Morning", [first, second]);

    await pumpPage(tester, routineId);
    await tester.tap(find.text("1 of 2"));
    await tester.pumpAndSettle();

    expect(find.text("Long tones"), findsOneWidget);
    await tester.tap(find.text("Long tones"));
    await tester.pumpAndSettle();

    expect(find.text("2 of 2"), findsOneWidget);
    expect(find.byType(ExerciseCard), findsOneWidget);
  });

  testWidgets("an empty routine says so", (tester) async {
    final routineId = await createRoutine("Morning", []);

    await pumpPage(tester, routineId);

    expect(find.text("This routine has no exercises."), findsOneWidget);
  });
}
