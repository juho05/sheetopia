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
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/practice_timer.dart';
import 'package:sheetopia/utils/app_shutdown.dart';

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
    List<String> exerciseIds,
  ) async {
    final exercises = await repo.getExercisesById(exerciseIds);
    final routineId = await repo.createRoutine(
      name: name,
      description: "",
      entries: [
        for (final exerciseId in exerciseIds)
          PracticeRoutineEntry(
            id: repo.newRoutineEntryId(),
            exercise: exercises[exerciseId]!,
            targetDuration: null,
          ),
      ],
    );
    return (await repo.getRoutine(routineId))!;
  }

  /// Leaves a stopwatch behind as an app that went away would.
  Future<String> leaveRunning(
    String exerciseId, {
    required Duration counted,
    required Duration ago,
  }) async {
    final session = await repo.startSession();
    final entry = await repo.startSessionEntry(
      sessionId: session.id,
      exerciseId: exerciseId,
    );
    await db.managers.practiceSessionEntriesTable
        .filter((f) => f.id(entry.id))
        .update(
          (o) => o(
            duration: Value(counted),
            runningSince: Value(DateTime.now().subtract(ago).toUtc()),
          ),
        );
    return session.id;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("practice_timer_test");
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

  test("no session is written before an exercise is started", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);

    expect(timer.session, isNull);
    expect(await db.managers.practiceSessionsTable.count(), 0);

    await timer.start();
    expect(timer.session, isNotNull);
    expect(await db.managers.practiceSessionsTable.count(), 1);
    timer.dispose();
  });

  test("closing ends the session and stops the stopwatch", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);
    await timer.start();
    await timer.close();
    timer.dispose();

    final session = (await db.managers.practiceSessionsTable.get()).single;
    expect(session.endedAt, isNotNull);
    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(entry.runningSince, isNull, reason: "the stopwatch is not running");
  });

  test("time already practiced is picked up again", () async {
    final exercise = await createExercise("Scales");
    final session = await repo.startSession();
    final entry = await repo.startSessionEntry(
      sessionId: session.id,
      exerciseId: exercise,
    );
    await repo.checkpointSessionEntry(
      entry,
      now: entry.runningSince!.add(const Duration(minutes: 4)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);

    expect(timer.elapsed, const Duration(minutes: 4));
    await timer.start();
    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 4)));
    timer.dispose();
  });

  test("a short gap is counted and the stopwatch keeps running", () async {
    final exercise = await createExercise("Scales");
    final sessionId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 3),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));

    expect(timer.recovery, isNull);
    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 5)));
    expect(
      timer.running,
      isTrue,
      reason: "no dialog and no start button, it just carries on",
    );
    expect(timer.session?.id, sessionId, reason: "the session continues");
    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(entry.runningSince, isNotNull);
    timer.dispose();
  });

  test("the session of the running stopwatch wins over a newer one", () async {
    final exercise = await createExercise("Scales");
    final sessionId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 3),
    );
    final newer = await repo.startSession();

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);

    expect(timer.session?.id, sessionId, reason: "not ${newer.id}");
    expect(timer.running, isTrue);
    timer.dispose();
  });

  test("a gap past the target duration is asked about", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));

    final recovery = timer.recovery;
    expect(recovery, isNotNull);
    expect(recovery!.counted, const Duration(minutes: 2));
    expect(recovery.gap, greaterThanOrEqualTo(const Duration(minutes: 30)));
    expect(timer.elapsed, const Duration(minutes: 2));
    timer.dispose();
  });

  test("without a target only long gaps are asked about", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: Duration.zero,
      ago: const Duration(minutes: 7),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);

    expect(timer.recovery, isNull, reason: "seven minutes stay under ten");
    timer.dispose();
  });

  test("discarding drops the time of the exercise", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.discard);

    expect(timer.recovery, isNull);
    expect(timer.elapsed, Duration.zero);
    expect(await db.managers.practiceSessionEntriesTable.count(), 0);
    timer.dispose();
  });

  test("keeping the counted time ignores the gap", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.untilLeft);

    expect(timer.elapsed, const Duration(minutes: 2));
    expect(timer.started, isFalse, reason: "the stopwatch waits to be resumed");
    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(entry.duration, const Duration(minutes: 2));
    expect(entry.runningSince, isNull);
    timer.dispose();
  });

  test("counting until now adds the gap and keeps running", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.untilNow);

    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 32)));
    expect(timer.running, isTrue, reason: "whoever counts until now goes on");
    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(entry.runningSince, isNotNull);
    timer.dispose();
  });

  test("closing the app with an unanswered question leaves it for the "
      "next start", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );
    final before = (await db.managers.practiceSessionEntriesTable.get()).single;

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    expect(timer.recovery, isNotNull);

    appIsClosing = true;
    addTearDown(() => appIsClosing = false);
    await timer.close();
    timer.dispose();

    final after = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(after.duration, before.duration, reason: "the gap is not counted");
    expect(after.runningSince, before.runningSince);
  });

  test("a stopwatch left running in another session is settled when "
      "something else is shown", () async {
    final exercise = await createExercise("Scales");
    final other = await createExercise("Arpeggios");
    final sessionId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 40),
    );
    final routine = await createRoutine("Morning", [other]);

    final timer = PracticeTimer(repo: repo);
    await timer.openSession(routineId: routine.id);
    await timer.show(
      exerciseId: other,
      routineEntryId: routine.entries.single.id,
    );

    expect(timer.recovery, isNull);
    expect(await repo.getRunningSessionEntry(), isNull);
    final left = (await repo.getSession(sessionId))!.entries.single;
    expect(left.duration, const Duration(minutes: 2));
    timer.dispose();
  });

  test("leaving with an unanswered question keeps only the counted "
      "time", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.close();
    timer.dispose();

    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(entry.duration, const Duration(minutes: 2));
    expect(entry.runningSince, isNull);
  });

  test("a stopwatch of another exercise counts up to its last "
      "checkpoint", () async {
    final exercise = await createExercise("Scales");
    final other = await createExercise("Arpeggios");
    final sessionId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: other);

    expect(timer.recovery, isNull);
    final session = (await repo.getSession(sessionId))!;
    final left = session.entries.firstWhere((e) => e.exerciseId == exercise);
    expect(left.duration, const Duration(minutes: 2));
    expect(left.runningSince, isNull);
    timer.dispose();
  });

  test("closing the app keeps the stopwatch running", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);
    await timer.start();

    appIsClosing = true;
    addTearDown(() => appIsClosing = false);
    await timer.close();
    timer.dispose();

    final entry = (await db.managers.practiceSessionEntriesTable.get()).single;
    expect(
      entry.runningSince,
      isNotNull,
      reason: "the next start picks the exercise up again",
    );
    final session = (await db.managers.practiceSessionsTable.get()).single;
    expect(session.endedAt, isNull, reason: "the session is not over");
  });

  group("ticking", () {
    test("the tick waits for the second to turn over", () {
      const slack = Duration(milliseconds: 8);
      expect(
        PracticeTimer.tickDelay(Duration.zero),
        const Duration(seconds: 1) + slack,
      );
      expect(
        PracticeTimer.tickDelay(const Duration(milliseconds: 1250)),
        const Duration(milliseconds: 750) + slack,
      );
      expect(
        PracticeTimer.tickDelay(const Duration(milliseconds: 999)),
        const Duration(milliseconds: 1) + slack,
      );
      expect(
        PracticeTimer.tickDelay(const Duration(minutes: 3, milliseconds: 40)),
        const Duration(milliseconds: 960) + slack,
      );
    });
  });

  test("a new session counts from zero and keeps the time so far", () async {
    final exercise = await createExercise("Scales");
    final session = await repo.startSession();
    final entry = await repo.startSessionEntry(
      sessionId: session.id,
      exerciseId: exercise,
    );
    await repo.checkpointSessionEntry(
      entry,
      now: entry.runningSince!.add(const Duration(minutes: 6)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.openSession();
    await timer.show(exerciseId: exercise);
    expect(timer.elapsed, const Duration(minutes: 6));

    await timer.startNewSession();

    expect(timer.session?.id, isNot(session.id));
    expect(timer.running, isTrue);
    expect(timer.elapsed, lessThan(const Duration(seconds: 5)));
    expect(
      await repo.getPracticedOn(DateTime.now()),
      greaterThanOrEqualTo(const Duration(minutes: 6)),
      reason: "the earlier session still counts as practiced",
    );
    timer.dispose();
  });
}
