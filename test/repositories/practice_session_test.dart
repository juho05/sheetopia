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
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/routing/practice_resume.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

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

  Future<String> createExercise(String name) => repo.createExercise(
    name: name,
    description: "",
    instrument: "",
    source: "",
    sourceLink: "",
    tagIds: const [],
  );

  Future<PracticeRoutine> createRoutine(
    String name,
    Map<String, Duration?> targets,
  ) async {
    final exercises = await repo.getExercisesById(targets.keys);
    final routineId = await repo.createRoutine(
      name: name,
      description: "",
      entries: [
        for (final entry in targets.entries)
          PracticeRoutineEntry(
            id: repo.newRoutineEntryId(),
            exercise: exercises[entry.key]!,
            targetDuration: entry.value,
          ),
      ],
    );
    return (await repo.getRoutine(routineId))!;
  }

  /// Backdates a session and its entries as if it had run then.
  Future<void> backdate(String sessionId, DateTime endedAt) async {
    await db.managers.practiceSessionsTable
        .filter((f) => f.id(sessionId))
        .update(
          (o) => o(
            startedAt: Value(endedAt.toUtc()),
            endedAt: Value(endedAt.toUtc()),
          ),
        );
    await db.managers.practiceSessionEntriesTable
        .filter((f) => f.session.id(sessionId))
        .update((o) => o(startedAt: Value(endedAt.toUtc())));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("practice_session_test");
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

  group("session boundaries", () {
    test("a routine session started today is resumed", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final session = await repo.startSession(routineId: routine.id);
      await backdate(session.id, DateTime(2026, 3, 10, 6, 0));

      final resumed = await repo.resumeOrStartSession(
        routineId: routine.id,
        routineTarget: routine.targetDuration,
        now: DateTime(2026, 3, 10, 21, 0),
      );
      expect(
        resumed.id,
        session.id,
        reason: "the same day resumes no matter the gap",
      );
    });

    test("a session of another day only resumes inside the window", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 30),
      });
      final session = await repo.startSession(routineId: routine.id);
      final now = DateTime(2026, 3, 10, 1, 0);

      await backdate(session.id, DateTime(2026, 3, 9, 23, 0));
      expect(
        (await repo.resumeOrStartSession(
          routineId: routine.id,
          routineTarget: routine.targetDuration,
          now: now,
        )).id,
        session.id,
        reason: "two hours are inside the three hour minimum",
      );

      await backdate(session.id, DateTime(2026, 3, 9, 20, 0));
      expect(
        (await repo.resumeOrStartSession(
          routineId: routine.id,
          routineTarget: routine.targetDuration,
          now: now,
        )).id,
        isNot(session.id),
      );
    });

    test("twice the target duration widens the window", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Long", {
        exercise: const Duration(hours: 3),
      });
      final session = await repo.startSession(routineId: routine.id);
      await backdate(session.id, DateTime(2026, 3, 9, 20, 0));

      final resumed = await repo.resumeOrStartSession(
        routineId: routine.id,
        routineTarget: routine.targetDuration,
        now: DateTime(2026, 3, 10, 1, 0),
      );
      expect(
        resumed.id,
        session.id,
        reason: "six hours of window cover the five hour gap",
      );
    });

    test("exercises outside a routine group within half an hour", () async {
      final session = await repo.startSession();
      await backdate(
        session.id,
        DateTime.now().subtract(const Duration(minutes: 20)),
      );
      expect((await repo.resumeOrStartSession()).id, session.id);

      await backdate(
        session.id,
        DateTime.now().subtract(const Duration(minutes: 40)),
      );
      expect((await repo.resumeOrStartSession()).id, isNot(session.id));
    });

    test("a session left running is always picked up", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.id(entry.id))
          .update(
            (o) => o(
              runningSince: Value(
                DateTime.now().subtract(const Duration(days: 2)).toUtc(),
              ),
            ),
          );

      final resumed = await repo.resumeOrStartSession();
      expect(resumed.id, session.id);
      expect(resumed.runningEntry, isNotNull);
    });

    test("a new session is started for the routine on reset", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final session = await repo.resumeOrStartSession(routineId: routine.id);
      await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routine.entries.first.id,
      );

      final reset = await repo.startNewSession(routineId: routine.id);
      expect(reset.id, isNot(session.id));
      expect(reset.entries, isEmpty);
      expect(
        (await repo.startNewSession(routineId: routine.id)).id,
        reset.id,
        reason: "an untouched session is nothing to reset",
      );
    });

    test("a reset settles a stopwatch left running", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final session = await repo.startSession(routineId: routine.id);
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routine.entries.first.id,
      );
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.id(entry.id))
          .update(
            (o) => o(
              duration: const Value(Duration(minutes: 3)),
              runningSince: Value(
                DateTime.now().subtract(const Duration(hours: 1)).toUtc(),
              ),
            ),
          );

      final reset = await repo.startNewSession(routineId: routine.id);
      expect(reset.id, isNot(session.id));
      expect(await repo.getRunningSessionEntry(), isNull);
      final settled = (await repo.getSession(session.id))!.entries.single;
      expect(settled.duration, const Duration(minutes: 3));
    });

    test("a stale untouched session is not reused on reset", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final stale = await repo.startSession(routineId: routine.id);
      await backdate(
        stale.id,
        DateTime.now().subtract(const Duration(days: 3)),
      );

      final reset = await repo.startNewSession(routineId: routine.id);
      expect(reset.id, isNot(stale.id));
      final endedAt = (await repo.getSession(stale.id))!.endedAt!;
      expect(
        endedAt.isBefore(DateTime.now().subtract(const Duration(days: 2))),
        isTrue,
        reason: "a session of another day is not ended today",
      );
    });
  });

  group("entries", () {
    test("starting the same exercise again continues its entry", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();

      final first = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await repo.checkpointSessionEntry(
        first,
        now: first.runningSince!.add(const Duration(minutes: 2)),
        stop: true,
      );
      final second = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );

      expect(second.id, first.id);
      expect(second.duration, const Duration(minutes: 2));
    });

    test("the same exercise twice in a routine is timed apart", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      await repo.addRoutineEntries(routine.id, [exercise]);
      final entries = (await repo.getRoutine(routine.id))!.entries;
      final session = await repo.startSession(routineId: routine.id);

      final first = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: entries.first.id,
      );
      final second = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: entries.last.id,
      );
      expect(second.id, isNot(first.id));
    });

    test("a stopwatch running over midnight splits the entry", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final startedAt = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        50,
      );
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.id(entry.id))
          .update(
            (o) => o(
              startedAt: Value(startedAt.toUtc()),
              runningSince: Value(startedAt.toUtc()),
            ),
          );

      final today = DateTime.now();
      final at = DateTime(today.year, today.month, today.day, 0, 20);
      final next = await repo.checkpointSessionEntry(
        (await repo.getSession(session.id))!.entries.single,
        now: at,
      );

      final reloaded = (await repo.getSession(session.id))!;
      expect(reloaded.entries, hasLength(2));
      expect(reloaded.entries.first.duration, const Duration(minutes: 10));
      expect(reloaded.entries.first.runningSince, isNull);
      expect(next.duration, const Duration(minutes: 20));
      expect(next.startedAt.day, today.day);
      expect(
        reloaded.durationFor(exerciseId: exercise),
        const Duration(minutes: 30),
      );
    });

    test("discarding drops every entry of the exercise", () async {
      final exercise = await createExercise("Scales");
      final other = await createExercise("Arpeggios");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await repo.startSessionEntry(sessionId: session.id, exerciseId: other);

      await repo.discardSessionEntries(entry);

      final reloaded = (await repo.getSession(session.id))!;
      expect(reloaded.entries, hasLength(1));
      expect(reloaded.entries.single.exerciseId, other);
    });
  });

  group("practiced time", () {
    test("only the entries of that day count", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await repo.checkpointSessionEntry(
        entry,
        now: entry.runningSince!.add(const Duration(minutes: 12)),
        stop: true,
      );

      expect(
        await repo.getPracticedOn(DateTime.now()),
        const Duration(minutes: 12),
      );
      expect(
        await repo.getPracticedOn(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        Duration.zero,
      );
    });

    test("a running stopwatch counts towards today", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.id(entry.id))
          .update(
            (o) => o(
              runningSince: Value(
                DateTime.now().subtract(const Duration(minutes: 3)).toUtc(),
              ),
            ),
          );

      expect(
        await repo.getPracticedOn(DateTime.now()),
        greaterThanOrEqualTo(const Duration(minutes: 3)),
      );
    });

    test("routine entry times are reported per entry", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final routineEntryId = routine.entries.first.id;
      final session = await repo.startSession(routineId: routine.id);
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routineEntryId,
      );
      await repo.checkpointSessionEntry(
        entry,
        now: entry.runningSince!.add(const Duration(minutes: 7)),
        stop: true,
      );

      final current = await repo.getCurrentSession(
        routineId: routine.id,
        routineTarget: routine.targetDuration,
      );
      expect(current!.durationsByRoutineEntry(), {
        routineEntryId: const Duration(minutes: 7),
      });
    });
  });

  group("leaving the app", () {
    test("a stopwatch left running is found again", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final routineEntryId = routine.entries.first.id;
      final session = await repo.startSession(routineId: routine.id);
      await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routineEntryId,
      );

      expect(
        await runningPracticeLocation(repo),
        "/practice/routines/${routine.id}/details/play?startIndex=0",
      );
    });

    test(
      "an exercise practiced outside a routine reopens on its own",
      () async {
        final exercise = await createExercise("Scales");
        final session = await repo.startSession();
        await repo.startSessionEntry(
          sessionId: session.id,
          exerciseId: exercise,
        );

        expect(
          await runningPracticeLocation(repo),
          "/practice/exercises/$exercise/play",
        );
      },
    );

    test("nothing is reopened without a running stopwatch", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await repo.checkpointSessionEntry(entry, stop: true);

      expect(await runningPracticeLocation(repo), isNull);
    });

    test("a deleted exercise is settled instead of reopened", () async {
      final exercise = await createExercise("Scales");
      final session = await repo.startSession();
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
      );
      await repo.checkpointSessionEntry(
        entry,
        now: entry.runningSince!.add(const Duration(minutes: 2)),
      );
      await repo.deleteExercise(exercise);

      expect(await runningPracticeLocation(repo), isNull);
      final settled = (await repo.getSession(session.id))!.entries.single;
      expect(settled.runningSince, isNull);
      expect(settled.duration, const Duration(minutes: 2));
    });

    test("a routine that is gone settles its stopwatch", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final session = await repo.startSession(routineId: routine.id);
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routine.entries.first.id,
      );
      await repo.checkpointSessionEntry(
        entry,
        now: entry.runningSince!.add(const Duration(minutes: 2)),
      );
      await repo.deleteRoutine(routine.id);

      expect(await runningPracticeLocation(repo), isNull);
      expect(await repo.getRunningSessionEntry(), isNull);
      final settled = (await repo.getSession(session.id))!.entries.single;
      expect(settled.duration, const Duration(minutes: 2));
    });

    test("a running stopwatch counts towards its routine entry", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final routineEntryId = routine.entries.first.id;
      final session = await repo.startSession(routineId: routine.id);
      final entry = await repo.startSessionEntry(
        sessionId: session.id,
        exerciseId: exercise,
        routineEntryId: routineEntryId,
      );
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.id(entry.id))
          .update(
            (o) => o(
              runningSince: Value(
                DateTime.now().subtract(const Duration(minutes: 4)).toUtc(),
              ),
            ),
          );

      final current = (await repo.getSession(session.id))!;
      expect(current.durationsByRoutineEntry()[routineEntryId], Duration.zero);
      expect(
        current.durationsByRoutineEntry(now: DateTime.now())[routineEntryId],
        greaterThanOrEqualTo(const Duration(minutes: 4)),
      );
    });
  });
}
