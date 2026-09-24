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
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  Future<List<PracticeRecordsTableData>> allRecords() =>
      db.managers.practiceRecordsTable.get();

  /// Leaves a stopwatch behind as an app that went away would.
  Future<String> leaveRunning(
    String exerciseId, {
    required Duration counted,
    required Duration ago,
  }) async {
    final record = await repo.startRecord(exerciseId: exerciseId);
    await db.managers.practiceRecordsTable
        .filter((f) => f.id(record.id))
        .update(
          (o) => o(
            duration: Value(counted),
            runningSince: Value(DateTime.now().subtract(ago).toUtc()),
          ),
        );
    return record.id;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("practice_timer_test");
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

  test("nothing is written before an exercise is started", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);

    expect(await db.managers.practiceRecordsTable.count(), 0);

    await timer.start();
    expect(await db.managers.practiceRecordsTable.count(), 1);
    timer.dispose();
  });

  test("starting twice at once starts one record", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);

    await Future.wait([timer.start(), timer.start()]);

    final record = (await allRecords()).single;
    expect(record.runningSince, isNotNull);
    await timer.pause();
    await Future.wait([timer.resume(), timer.resume()]);
    expect(await allRecords(), hasLength(2));
    timer.dispose();
  });

  test("answering the question twice at once only applies the first "
      "answer", () async {
    final exercise = await createExercise("Scales");
    await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 20),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await Future.wait([
      timer.resolveRecovery(PracticeRecoveryChoice.untilLeft),
      timer.resolveRecovery(PracticeRecoveryChoice.discard),
    ]);

    expect(timer.recovery, isNull);
    expect(timer.started, isFalse);
    final record = (await allRecords()).single;
    expect(record.duration, const Duration(minutes: 2));
    expect(record.runningSince, isNull);
    timer.dispose();
  });

  test("closing stops the stopwatch", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);
    await timer.start();
    await timer.close();
    timer.dispose();

    final record = (await allRecords()).single;
    expect(record.runningSince, isNull, reason: "the stopwatch is not running");
    expect(record.uploaded, isFalse);
  });

  test("pausing right after starting leaves no record", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(
      repo: PracticeRepository(db: db, scoresRepo: scoresRepo),
    );
    await timer.show(exerciseId: exercise);
    await timer.start();
    await timer.pause();

    expect(await allRecords(), isEmpty);
    expect(timer.elapsed, Duration.zero);
    timer.dispose();
  });

  test("time already practiced is picked up again", () async {
    final exercise = await createExercise("Scales");
    final record = await repo.startRecord(exerciseId: exercise);
    await repo.checkpointRecord(
      record,
      now: record.runningSince!.add(const Duration(minutes: 4)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);

    expect(timer.elapsed, const Duration(minutes: 4));
    await timer.start();
    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 4)));
    expect(await allRecords(), hasLength(2), reason: "every run is a record");
    timer.dispose();
  });

  test("pause and resume keep counting on", () async {
    final exercise = await createExercise("Scales");
    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);
    await timer.start();
    await timer.pause();
    await db.managers.practiceRecordsTable.update(
      (o) => o(duration: const Value(Duration(minutes: 3))),
    );
    await timer.resume();

    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 3)));
    expect(await allRecords(), hasLength(2));
    timer.dispose();
  });

  test("a routine keeps its own time apart from the exercise", () async {
    final exercise = await createExercise("Scales");
    final routine = await createRoutine("Morning", [exercise]);
    final record = await repo.startRecord(exerciseId: exercise);
    await repo.checkpointRecord(
      record,
      now: record.runningSince!.add(const Duration(minutes: 4)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(
      exerciseId: exercise,
      routineId: routine.id,
      routineEntryId: routine.entries.single.id,
    );

    expect(timer.elapsed, Duration.zero);
    timer.dispose();
  });

  test("a short gap is counted and the stopwatch keeps running", () async {
    final exercise = await createExercise("Scales");
    final recordId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 3),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));

    expect(timer.recovery, isNull);
    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 5)));
    expect(
      timer.running,
      isTrue,
      reason: "no dialog and no start button, it just carries on",
    );
    final record = (await allRecords()).single;
    expect(record.id, recordId, reason: "the record continues");
    expect(record.runningSince, isNotNull);
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
    await timer.show(exerciseId: exercise);

    expect(timer.recovery, isNull, reason: "seven minutes stay under ten");
    timer.dispose();
  });

  test("discarding drops the run and keeps earlier practice", () async {
    final exercise = await createExercise("Scales");
    final earlier = await repo.startRecord(exerciseId: exercise);
    await repo.checkpointRecord(
      earlier,
      now: earlier.runningSince!.add(const Duration(minutes: 3)),
      stop: true,
    );
    final left = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 20),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    expect(timer.recovery!.counted, const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.discard);

    expect(timer.recovery, isNull);
    expect(timer.elapsed, const Duration(minutes: 3));
    final rows = await allRecords();
    expect(rows.single.id, earlier.id);
    expect(
      (await db.managers.deletedPracticeRecordsTable.get()).single.recordId,
      left,
    );
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
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.untilLeft);

    expect(timer.elapsed, const Duration(minutes: 2));
    expect(timer.started, isFalse, reason: "the stopwatch waits to be resumed");
    final record = (await allRecords()).single;
    expect(record.duration, const Duration(minutes: 2));
    expect(record.runningSince, isNull);
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
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.resolveRecovery(PracticeRecoveryChoice.untilNow);

    expect(timer.elapsed, greaterThanOrEqualTo(const Duration(minutes: 32)));
    expect(timer.running, isTrue, reason: "whoever counts until now goes on");
    final record = (await allRecords()).single;
    expect(record.runningSince, isNotNull);
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
    final before = (await allRecords()).single;

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    expect(timer.recovery, isNotNull);

    appIsClosing = true;
    addTearDown(() => appIsClosing = false);
    await timer.close();
    timer.dispose();

    final after = (await allRecords()).single;
    expect(after.duration, before.duration, reason: "the gap is not counted");
    expect(after.runningSince, before.runningSince);
  });

  test("a stopwatch left running elsewhere is settled when something else "
      "is shown", () async {
    final exercise = await createExercise("Scales");
    final other = await createExercise("Arpeggios");
    final recordId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 40),
    );
    final routine = await createRoutine("Morning", [other]);

    final timer = PracticeTimer(repo: repo);
    await timer.show(
      exerciseId: other,
      routineId: routine.id,
      routineEntryId: routine.entries.single.id,
    );

    expect(timer.recovery, isNull);
    expect(await repo.getRunningRecord(), isNull);
    final left = (await repo.getRecord(recordId))!;
    expect(left.duration, const Duration(minutes: 2));
    timer.dispose();
  });

  test("the same exercise in a routine does not adopt an ad hoc "
      "stopwatch", () async {
    final exercise = await createExercise("Scales");
    final recordId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 1),
    );
    final routine = await createRoutine("Morning", [exercise]);

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise, routineId: routine.id);

    expect(timer.running, isFalse);
    expect((await repo.getRecord(recordId))!.running, isFalse);
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
    await timer.show(exerciseId: exercise, target: const Duration(minutes: 5));
    await timer.close();
    timer.dispose();

    final record = (await allRecords()).single;
    expect(record.duration, const Duration(minutes: 2));
    expect(record.runningSince, isNull);
  });

  test("a stopwatch of another exercise counts up to its last "
      "checkpoint", () async {
    final exercise = await createExercise("Scales");
    final other = await createExercise("Arpeggios");
    final recordId = await leaveRunning(
      exercise,
      counted: const Duration(minutes: 2),
      ago: const Duration(minutes: 30),
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: other);

    expect(timer.recovery, isNull);
    final left = (await repo.getRecord(recordId))!;
    expect(left.duration, const Duration(minutes: 2));
    expect(left.runningSince, isNull);
    timer.dispose();
  });

  test(
    "closing the app keeps the stopwatch running and publishes it",
    () async {
      final exercise = await createExercise("Scales");
      final timer = PracticeTimer(repo: repo);
      await timer.show(exerciseId: exercise);
      await timer.start();
      await db.managers.practiceRecordsTable.update(
        (o) => o(uploaded: const Value(true)),
      );

      appIsClosing = true;
      addTearDown(() => appIsClosing = false);
      await timer.close();
      timer.dispose();

      final record = (await allRecords()).single;
      expect(
        record.runningSince,
        isNotNull,
        reason: "the next start picks the exercise up again",
      );
      expect(record.uploaded, isFalse);
    },
  );

  group("lifecycle", () {
    final binding = TestWidgetsFlutterBinding.instance;

    void lifecycle(List<AppLifecycleState> states) {
      for (final state in states) {
        binding.handleAppLifecycleStateChanged(state);
      }
    }

    setUp(() => lifecycle([AppLifecycleState.resumed]));

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    Future<int> ticksWithin(PracticeTimer timer, Duration duration) async {
      var ticks = 0;
      void count() => ticks++;
      timer.ticks.addListener(count);
      await Future<void>.delayed(duration);
      timer.ticks.removeListener(count);
      return ticks;
    }

    const away = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];
    const back = [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ];

    test("android stops ticking in the background and goes on after", () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final exercise = await createExercise("Scales");
      final timer = PracticeTimer(repo: repo);
      await timer.show(exerciseId: exercise);
      await timer.start();

      lifecycle(away);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(await ticksWithin(timer, const Duration(milliseconds: 1500)), 0);
      final record = (await allRecords()).single;
      expect(record.runningSince, isNotNull);

      lifecycle(back);
      expect(timer.running, isTrue);
      expect(
        await ticksWithin(timer, const Duration(milliseconds: 1500)),
        greaterThan(0),
      );
      await timer.close();
      timer.dispose();
    });

    test("desktop keeps ticking in the background", () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final exercise = await createExercise("Scales");
      final timer = PracticeTimer(repo: repo);
      await timer.show(exerciseId: exercise);
      await timer.start();

      lifecycle(away.take(2).toList());
      expect(
        await ticksWithin(timer, const Duration(milliseconds: 1500)),
        greaterThan(0),
      );
      await timer.close();
      timer.dispose();
    });
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

  test("a reset counts from zero and keeps the time so far", () async {
    final exercise = await createExercise("Scales");
    final record = await repo.startRecord(exerciseId: exercise);
    await repo.checkpointRecord(
      record,
      now: record.runningSince!.add(const Duration(minutes: 6)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(exerciseId: exercise);
    expect(timer.elapsed, const Duration(minutes: 6));

    await timer.resetProgress();

    expect(timer.running, isTrue);
    expect(timer.elapsed, lessThan(const Duration(seconds: 5)));
    expect(
      await repo.getPracticedOn(DateTime.now()),
      greaterThanOrEqualTo(const Duration(minutes: 6)),
      reason: "the earlier record still counts as practiced",
    );
    timer.dispose();
  });

  test("a routine reset starts over for every entry", () async {
    final exercise = await createExercise("Scales");
    final other = await createExercise("Arpeggios");
    final routine = await createRoutine("Morning", [exercise, other]);
    final record = await repo.startRecord(
      exerciseId: other,
      routineId: routine.id,
      routineEntryId: routine.entries.last.id,
    );
    await repo.checkpointRecord(
      record,
      now: record.runningSince!.add(const Duration(minutes: 6)),
      stop: true,
    );

    final timer = PracticeTimer(repo: repo);
    await timer.show(
      exerciseId: exercise,
      routineId: routine.id,
      routineEntryId: routine.entries.first.id,
    );
    await timer.resetProgress();
    await timer.pause();

    final progress = await repo.getRoutineProgress(routine.id);
    expect(progress.byRoutineEntry().keys, [routine.entries.first.id]);
    timer.dispose();
  });
}
