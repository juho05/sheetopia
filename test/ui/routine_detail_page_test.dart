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
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/routine_detail_page.dart';

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

  Future<PracticeRoutineEntry> entry(
    String exerciseId, {
    Duration? targetDuration,
  }) async => PracticeRoutineEntry(
    id: repo.newRoutineEntryId(),
    exercise: (await repo.getExercisesById([exerciseId]))[exerciseId]!,
    targetDuration: targetDuration,
  );

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
}
