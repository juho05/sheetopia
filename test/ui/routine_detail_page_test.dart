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
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/practice/exercise_tile.dart';
import 'package:sheetopia/ui/practice/routine_detail_page.dart';

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

  Future<String> createExercise(String name, {String instrument = ""}) =>
      repo.createExercise(
        name: name,
        description: "",
        instrument: instrument,
        source: "",
        sourceLink: "",
        tagIds: const [],
      );

  Future<PracticeRoutineEntry> entry(
    String exerciseId, {
    Duration? targetDuration,
    String? defaultScoreId,
  }) async => PracticeRoutineEntry(
    id: repo.newRoutineEntryId(),
    exercise: (await repo.getExercisesById([exerciseId]))[exerciseId]!,
    targetDuration: targetDuration,
    defaultScoreId: defaultScoreId,
  );

  Future<void> insertScore(String id) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileDownloaded: true,
        fileType: FileType.pdf,
        type: const Value(ScoreType.exercise),
      ),
    );
  }

  void setWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("routine_detail_page_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    // resolving score files creates directories, the fake async zone of a
    // widget test never lets that land
    await scoresRepo.scoresDir;
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpPage(WidgetTester tester, String routineId) async {
    final router = GoRouter(
      initialLocation: "/practice/routines/$routineId/details",
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => const Text("back"),
          routes: [
            GoRoute(
              path: "practice/routines/:routineId/details",
              builder: (context, state) => RoutineDetailPage(
                routineId: state.pathParameters["routineId"]!,
              ),
              routes: [
                GoRoute(
                  path: "edit",
                  builder: (context, state) => const Text("edit page"),
                ),
              ],
            ),
            GoRoute(
              path: "practice/routines/:routineId/details/play",
              builder: (context, state) => Text(
                "play page ${state.uri.queryParameters["startIndex"] ?? "none"}",
              ),
            ),
          ],
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
    await settle(tester);
  }

  testWidgets("the routine is shown with its entries", (tester) async {
    final first = await createExercise("Chromatic", instrument: "Guitar");
    final second = await createExercise("Long tones");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: [
        await entry(first, targetDuration: const Duration(minutes: 20)),
        await entry(second),
      ],
    );

    await pumpPage(tester, routineId);

    expect(find.text("Morning"), findsOneWidget);
    expect(find.text("Every day"), findsOneWidget);
    expect(find.text("2 exercises • 20min"), findsOneWidget);
    expect(find.text("Chromatic"), findsOneWidget);
    expect(find.text("Guitar"), findsOneWidget);
    expect(find.text("20min"), findsOneWidget);
    expect(find.text("Long tones"), findsOneWidget);
    expect(find.text("No target"), findsOneWidget);
  });

  testWidgets("nothing on the page can be edited", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId);

    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ReorderableDragStartListener), findsNothing);
    expect(find.text("Add exercises"), findsNothing);
  });

  testWidgets("a routine without exercises says so", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId);

    expect(find.text("No exercises yet."), findsOneWidget);
    expect(find.text("0 exercises"), findsOneWidget);
  });

  testWidgets("the play button waits for exercises", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId);

    final play = find.widgetWithText(FilledButton, "Play");
    expect(play, findsOneWidget);
    expect(tester.widget<FilledButton>(play).onPressed, isNull);
  });

  testWidgets("a routine with exercises can be played", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId);

    final play = find.widgetWithText(FilledButton, "Play");
    expect(tester.widget<FilledButton>(play).onPressed, isNotNull);

    await tester.tap(play);
    await tester.pumpAndSettle();

    expect(find.text("play page none"), findsOneWidget);
  });

  testWidgets("tapping an entry plays the routine from there", (tester) async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Long tones");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(first), await entry(second)],
    );

    await pumpPage(tester, routineId);
    await tester.tap(find.text("Long tones"));
    await tester.pumpAndSettle();

    expect(find.text("play page 1"), findsOneWidget);
  });

  testWidgets("the edit button opens the edit page", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId);
    await tester.tap(find.widgetWithText(OutlinedButton, "Edit"));
    await tester.pumpAndSettle();

    expect(find.text("edit page"), findsOneWidget);
  });

  testWidgets("an edit elsewhere is picked up", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId);
    await repo.updateRoutine(routineId, name: "Evening", description: "Later");
    await settle(tester);

    expect(find.text("Evening"), findsOneWidget);
    expect(find.text("Later"), findsOneWidget);
  });

  testWidgets("the page closes when the routine is deleted", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId);
    await repo.deleteRoutine(routineId);
    await tester.pumpAndSettle();

    expect(find.text("back"), findsOneWidget);
  });

  testWidgets("an unknown routine is reported", (tester) async {
    await pumpPage(tester, "nope");

    expect(find.text("This routine no longer exists."), findsOneWidget);
  });

  testWidgets("the default score is shown on the right when wide", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic", instrument: "Guitar");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [
        await entry(
          exerciseId,
          targetDuration: const Duration(minutes: 20),
          defaultScoreId: "b",
        ),
      ],
    );

    await pumpPage(tester, routineId);

    expect(find.text("Title b"), findsOneWidget);
    // out of the badge strip, next to the target duration instead
    expect(
      tester.widget<ExerciseTile>(find.byType(ExerciseTile)).leadingBadge,
      isNull,
    );
    expect(
      tester.getRect(find.text("Title b")).left,
      greaterThan(tester.getRect(find.text("Guitar")).left),
    );
    expect(
      tester.getRect(find.text("Title b")).left,
      lessThan(tester.getRect(find.text("20min")).left),
    );
  });

  testWidgets("the default score moves into the badge strip when narrow", (
    tester,
  ) async {
    setWidth(tester, 360);
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic", instrument: "Guitar");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "b")],
    );

    await pumpPage(tester, routineId);

    expect(
      tester.widget<ExerciseTile>(find.byType(ExerciseTile)).leadingBadge,
      isNotNull,
    );
    expect(find.text("Title b"), findsOneWidget);
    // it sits before the instrument so the tags scroll off instead
    expect(
      tester.getRect(find.text("Title b")).left,
      lessThan(tester.getRect(find.text("Guitar")).left),
    );
    expect(
      tester.getSize(find.byType(ExerciseTile)).height,
      RoundedListTile.defaultHeight + RoundedListTile.spacing,
    );
  });

  testWidgets("without an explicit default the first score is shown", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId);

    expect(find.text("Title a"), findsOneWidget);
    expect(find.text("Title b"), findsNothing);
  });

  testWidgets("a default score that is gone falls back to the first", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "elsewhere")],
    );

    await pumpPage(tester, routineId);

    expect(find.text("Title a"), findsOneWidget);
  });

  testWidgets("an exercise with a single score shows no default", (
    tester,
  ) async {
    await insertScore("a");
    final exerciseId = await createExercise("Chromatic");
    await repo.setExerciseScores(exerciseId, ["a"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "a")],
    );

    await pumpPage(tester, routineId);

    expect(
      tester.widget<ExerciseTile>(find.byType(ExerciseTile)).leadingBadge,
      isNull,
    );
    expect(find.textContaining("Title"), findsNothing);
  });

  testWidgets("an exercise without scores shows no default", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId);

    expect(
      tester.widget<ExerciseTile>(find.byType(ExerciseTile)).leadingBadge,
      isNull,
    );
    expect(find.textContaining("Title"), findsNothing);
  });
}
