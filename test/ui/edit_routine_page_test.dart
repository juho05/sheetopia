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
import 'package:sheetopia/ui/practice/edit_routine_page.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/practice/exercise_tile.dart';

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
  late PracticeRepository repo;
  late ScoresRepository scoresRepo;

  Future<String> createExercise(
    String name, {
    List<String> scoreIds = const [],
  }) => repo.createExercise(
    name: name,
    description: "",
    instrument: "",
    source: "",
    sourceLink: "",
    tagIds: const [],
    scoreIds: scoreIds,
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

  Future<String?> defaultScoreOf(String routineId) async =>
      (await db.managers.practiceRoutineEntriesTable
              .filter((f) => f.routine.id(routineId))
              .getSingle())
          .defaultScore;

  Future<PracticeRoutineEntry> entry(
    String exerciseId, {
    Duration? targetDuration,
  }) async => PracticeRoutineEntry(
    id: repo.newRoutineEntryId(),
    exercise: (await repo.getExercisesById([exerciseId]))[exerciseId]!,
    targetDuration: targetDuration,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("edit_routine_page_test");
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

  Future<void> pumpPage(WidgetTester tester, {String? routineId}) async {
    final router = GoRouter(
      initialLocation: "/edit",
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => const Text("back"),
          routes: [
            GoRoute(
              path: "edit",
              builder: (context, state) =>
                  EditRoutinePage(routineId: routineId),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PracticeRepository>.value(value: repo),
          // the exercise picker offers creating an exercise from a score
          Provider<ScoresRepository>.value(value: scoresRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  testWidgets("the create page starts empty", (tester) async {
    await pumpPage(tester);

    expect(find.text("Create routine"), findsOneWidget);
    expect(find.text("0 exercises"), findsOneWidget);
    expect(find.text("Add exercises"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Create"), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, "Create"))
          .onPressed,
      isNull,
    );
  });

  testWidgets("a routine is created with its exercises", (tester) async {
    await createExercise("Chromatic");
    await pumpPage(tester);

    await tester.enterText(find.widgetWithText(TextField, "Name"), "Morning");
    await settle(tester);

    await tester.tap(find.text("Add exercises"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Chromatic"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Add"));
    await settle(tester);

    expect(find.text("1 exercise"), findsOneWidget);
    expect(await db.managers.practiceRoutinesTable.count(), 0);

    await tester.tap(find.widgetWithText(FilledButton, "Create"));
    await tester.pumpAndSettle();

    final routines = await repo.getRoutines(size: 10);
    final routine = await repo.getRoutine(routines.single.id);
    expect(routine!.name, "Morning");
    expect(routine.entries.single.exercise.name, "Chromatic");
    expect(find.text("back"), findsOneWidget);
  });

  testWidgets("an existing routine is shown with its entries", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: [
        await entry(exerciseId, targetDuration: const Duration(minutes: 20)),
      ],
    );

    await pumpPage(tester, routineId: routineId);

    expect(find.text("Edit routine"), findsOneWidget);
    expect(find.text("Morning"), findsOneWidget);
    expect(find.text("Every day"), findsOneWidget);
    expect(find.text("Chromatic"), findsOneWidget);
    expect(find.text("20"), findsOneWidget);
    expect(find.text("1 exercise • 20min"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Delete"), findsOneWidget);
  });

  testWidgets("editing an entry updates the routine", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );
    final entryId = (await repo.getRoutine(routineId))!.entries.single.id;

    await pumpPage(tester, routineId: routineId);
    await tester.enterText(
      find.descendant(
        of: find.byTooltip("Target duration"),
        matching: find.byType(TextField),
      ),
      "30",
    );
    await settle(tester);

    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.single.targetDuration, const Duration(minutes: 30));
    expect(routine.entries.single.id, entryId);
  });

  testWidgets("an entry can be removed", (tester) async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId: routineId);
    await tester.tap(find.byTooltip("Remove exercise"));
    await settle(tester);

    expect(find.text("Chromatic"), findsNothing);
    expect((await repo.getRoutine(routineId))!.entries, isEmpty);
  });

  testWidgets("a wide entry shows the default score inline", (tester) async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic", scoreIds: ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId: routineId);

    final tile = tester.widget<ExerciseTile>(find.byType(ExerciseTile));
    expect(tile.subtitle, isNull);
    expect(tile.showBadges, isTrue);
    expect(find.byType(ExerciseScoreSelector), findsOneWidget);
    expect(find.text("Title a"), findsOneWidget);
  });

  testWidgets("a narrow entry moves the selector below the title", (
    tester,
  ) async {
    setWidth(tester, 360);
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic", scoreIds: ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId: routineId);

    final tile = tester.widget<ExerciseTile>(find.byType(ExerciseTile));
    expect(tile.subtitle, isNotNull);
    expect(tile.showBadges, isFalse);
    expect(find.byType(ExerciseScoreSelector), findsOneWidget);
    // the tile keeps the height every other exercise tile has
    expect(
      tester.getSize(find.byType(ExerciseTile)).height,
      RoundedListTile.defaultHeight + RoundedListTile.spacing,
    );
  });

  testWidgets("a single score entry has no selector", (tester) async {
    setWidth(tester, 360);
    await insertScore("a");
    final exerciseId = await createExercise("Chromatic", scoreIds: ["a"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId: routineId);

    expect(
      tester.widget<ExerciseTile>(find.byType(ExerciseTile)).subtitle,
      isNull,
    );
    expect(find.byType(ExerciseScoreSelector), findsNothing);
  });

  testWidgets("choosing an alternative saves it as the default", (
    tester,
  ) async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Chromatic", scoreIds: ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await pumpPage(tester, routineId: routineId);
    await tester.tap(find.byType(ExerciseScoreSelector));
    await tester.pumpAndSettle();

    expect(find.text("Default score"), findsOneWidget);

    await tester.tap(find.text("Title b").last);
    await settle(tester);

    expect(await defaultScoreOf(routineId), "b");
  });

  testWidgets("a missing routine is reported", (tester) async {
    await pumpPage(tester, routineId: "nope");

    expect(find.text("This routine no longer exists."), findsOneWidget);
  });

  testWidgets("deleting asks for a confirmation first", (tester) async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    await pumpPage(tester, routineId: routineId);
    await tester.tap(find.widgetWithText(FilledButton, "Delete"));
    await tester.pumpAndSettle();

    expect(find.text("Delete routine?"), findsOneWidget);
    expect(
      find.textContaining("will be deleted on all your devices"),
      findsOneWidget,
    );

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(await repo.getRoutine(routineId), isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, "Delete"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Yes"));
    await tester.pumpAndSettle();

    expect(await repo.getRoutine(routineId), isNull);
  });
}
