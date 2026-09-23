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

  Future<List<PracticeRecordsTableData>> allRecords() => (db.select(
    db.practiceRecordsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.startedAt)])).get();

  /// Moves a stopped record back in time as if it had run then.
  Future<void> backdate(String recordId, DateTime startedAt) async {
    await db.managers.practiceRecordsTable
        .filter((f) => f.id(recordId))
        .update((o) => o(startedAt: Value(startedAt.toUtc())));
  }

  Future<void> setRunningSince(String recordId, DateTime runningSince) async {
    await db.managers.practiceRecordsTable
        .filter((f) => f.id(recordId))
        .update((o) => o(runningSince: Value(runningSince.toUtc())));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("practice_record_test");
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

  group("records", () {
    test("starting creates a running record marked for upload", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);

      expect(record.running, isTrue);
      final row = (await allRecords()).single;
      expect(row.id, record.id);
      expect(row.exercise, exercise);
      expect(row.routine, isNull);
      expect(row.runningSince, isNotNull);
      expect(row.uploaded, isFalse);
    });

    test("starting the same exercise again creates another record", () async {
      final exercise = await createExercise("Scales");
      final first = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(
        first,
        now: first.runningSince!.add(const Duration(minutes: 2)),
        stop: true,
      );
      final second = await repo.startRecord(exerciseId: exercise);

      expect(second.id, isNot(first.id));
      expect(second.duration, Duration.zero);
      final progress = await repo.getExerciseProgress(exercise);
      expect(progress.records, hasLength(2));
      expect(
        progress.durationFor(exerciseId: exercise),
        const Duration(minutes: 2),
      );
    });

    test("a tick checkpoint stays local, a stop publishes", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await db.managers.practiceRecordsTable.update(
        (o) => o(uploaded: const Value(true)),
      );

      final ticked = await repo.checkpointRecord(
        record,
        now: record.runningSince!.add(const Duration(seconds: 5)),
      );
      expect(ticked.duration, const Duration(seconds: 5));
      expect(ticked.running, isTrue);
      expect((await allRecords()).single.uploaded, isTrue);

      await repo.checkpointRecord(
        ticked,
        now: ticked.runningSince!.add(const Duration(seconds: 5)),
        publish: true,
      );
      expect((await allRecords()).single.uploaded, isFalse);

      await db.managers.practiceRecordsTable.update(
        (o) => o(uploaded: const Value(true)),
      );
      final stopped = await repo.checkpointRecord(
        (await repo.getRunningRecord())!,
        stop: true,
      );
      expect(stopped.running, isFalse);
      final row = (await allRecords()).single;
      expect(row.uploaded, isFalse);
      expect(row.runningSince, isNull);
    });

    test("the same exercise twice in a routine is timed apart", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      await repo.addRoutineEntries(routine.id, [exercise]);
      final entries = (await repo.getRoutine(routine.id))!.entries;

      final first = await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: entries.first.id,
      );
      await repo.checkpointRecord(
        first,
        now: first.runningSince!.add(const Duration(minutes: 3)),
        stop: true,
      );

      final progress = await repo.getRoutineProgress(routine.id);
      expect(progress.byRoutineEntry(), {
        entries.first.id: const Duration(minutes: 3),
      });
      expect(
        progress.durationFor(
          exerciseId: exercise,
          routineEntryId: entries.last.id,
        ),
        Duration.zero,
      );
    });

    test("a stopwatch running over midnight splits the record", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final startedAt = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        50,
      );
      await backdate(record.id, startedAt);
      await setRunningSince(record.id, startedAt);
      await db.managers.practiceRecordsTable.update(
        (o) => o(uploaded: const Value(true)),
      );

      final today = DateTime.now();
      final at = DateTime(today.year, today.month, today.day, 0, 20);
      final next = await repo.checkpointRecord(
        (await repo.getRunningRecord())!,
        now: at,
      );

      final rows = await allRecords();
      expect(rows, hasLength(2));
      expect(rows.first.duration, const Duration(minutes: 10));
      expect(rows.first.runningSince, isNull);
      expect(rows.first.uploaded, isFalse, reason: "the first half is done");
      expect(next.id, rows.last.id);
      expect(next.duration, const Duration(minutes: 20));
      expect(next.running, isTrue);
      expect(next.startedAt.day, today.day);
    });

    test("discarding drops only that run", () async {
      final exercise = await createExercise("Scales");
      final first = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(
        first,
        now: first.runningSince!.add(const Duration(minutes: 4)),
        stop: true,
      );
      final second = await repo.startRecord(exerciseId: exercise);

      await repo.discardRecord(second);

      final rows = await allRecords();
      expect(rows.single.id, first.id);
      final tombstones = await db.managers.deletedPracticeRecordsTable.get();
      expect(tombstones.single.recordId, second.id);
    });

    test("a manual delete leaves a tombstone", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await expectLater(repo.deleteRecord(record.id), throwsStateError);

      await repo.checkpointRecord(record, stop: true);
      await repo.deleteRecord(record.id);

      expect(await allRecords(), isEmpty);
      final tombstones = await db.managers.deletedPracticeRecordsTable.get();
      expect(tombstones.single.recordId, record.id);
    });

    test("a manual edit marks the record for upload", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await expectLater(
        repo.updateRecord(record.id, duration: const Duration(minutes: 1)),
        throwsStateError,
      );
      await repo.checkpointRecord(record, stop: true);
      await db.managers.practiceRecordsTable.update(
        (o) => o(uploaded: const Value(true)),
      );

      await repo.updateRecord(record.id, duration: const Duration(minutes: 9));

      final row = (await allRecords()).single;
      expect(row.duration, const Duration(minutes: 9));
      expect(row.uploaded, isFalse);
    });

    test("a manual create adds a stopped record marked for upload", () async {
      final exercise = await createExercise("Scales");
      final startedAt = DateTime(2026, 3, 4, 10, 30);
      final updated = expectLater(repo.updatedRecordIds, emits(hasLength(1)));

      final recordId = await repo.createRecord(
        exerciseId: exercise,
        startedAt: startedAt,
        duration: const Duration(minutes: 12),
      );

      await updated;
      final record = (await repo.getRecord(recordId))!;
      expect(record.running, isFalse);
      expect(record.exerciseId, exercise);
      expect(record.routineId, isNull);
      expect(record.startedAt, startedAt);
      expect(record.duration, const Duration(minutes: 12));
      expect((await allRecords()).single.uploaded, isFalse);
    });

    test("records are listed newest first in pages", () async {
      final exercise = await createExercise("Scales");
      for (var day = 1; day <= 5; day++) {
        await repo.createRecord(
          exerciseId: exercise,
          startedAt: DateTime(2026, 3, day, 10),
          duration: const Duration(minutes: 1),
        );
      }

      final first = await repo.getRecords(size: 3);
      final second = await repo.getRecords(size: 3, offset: 3);

      expect([for (final r in first) r.startedAt.day], [5, 4, 3]);
      expect([for (final r in second) r.startedAt.day], [2, 1]);
    });

    test("routine names are looked up by id", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {exercise: null});

      expect(await repo.getRoutineNames({routine.id, "missing"}), {
        routine.id: "Morning",
      });
    });
  });

  group("progress", () {
    test("exercises outside a routine group within half an hour", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(record, stop: true);

      await backdate(
        record.id,
        DateTime.now().subtract(const Duration(minutes: 20)),
      );
      expect((await repo.getExerciseProgress(exercise)).records, hasLength(1));

      await backdate(
        record.id,
        DateTime.now().subtract(const Duration(minutes: 40)),
      );
      expect((await repo.getExerciseProgress(exercise)).records, isEmpty);
    });

    test("routine records do not count for the exercise alone", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final record = await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: routine.entries.first.id,
      );
      await repo.checkpointRecord(record, stop: true);

      expect((await repo.getExerciseProgress(exercise)).records, isEmpty);
      expect((await repo.getRoutineProgress(routine.id)).records, hasLength(1));
    });

    test("a reset excludes the earlier records", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final record = await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: routine.entries.first.id,
      );
      await repo.checkpointRecord(record, stop: true);
      await backdate(
        record.id,
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await repo.resetRoutineProgress(routine.id);

      expect((await repo.getRoutineProgress(routine.id)).records, isEmpty);
      final routineRow = await db.managers.practiceRoutinesTable
          .filter((f) => f.id(routine.id))
          .getSingle();
      expect(routineRow.progressResetAt, isNotNull);
      expect(await allRecords(), hasLength(1), reason: "nothing is deleted");

      await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: routine.entries.first.id,
      );
      expect((await repo.getRoutineProgress(routine.id)).records, hasLength(1));
    });

    test("a reset stops a stopwatch left running", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await db.managers.practiceRecordsTable
          .filter((f) => f.id(record.id))
          .update((o) => o(duration: const Value(Duration(minutes: 3))));
      await setRunningSince(
        record.id,
        DateTime.now().subtract(const Duration(hours: 1)),
      );

      await repo.resetExerciseProgress(exercise);

      expect(await repo.getRunningRecord(), isNull);
      expect((await allRecords()).single.duration, const Duration(minutes: 3));
      expect((await repo.getExerciseProgress(exercise)).records, isEmpty);
      final row = await db.managers.exercisesTable
          .filter((f) => f.id(exercise))
          .getSingle();
      expect(row.progressResetAt, isNotNull);
      expect(row.uploaded, isFalse);
    });
  });

  group("practiced time", () {
    test("only the records of that day count", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(
        record,
        now: record.runningSince!.add(const Duration(minutes: 12)),
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
      final record = await repo.startRecord(exerciseId: exercise);
      await setRunningSince(
        record.id,
        DateTime.now().subtract(const Duration(minutes: 3)),
      );

      expect(
        await repo.getPracticedOn(DateTime.now()),
        greaterThanOrEqualTo(const Duration(minutes: 3)),
      );
    });
  });

  group("leaving the app", () {
    test("a stopwatch left running is found again", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: routine.entries.first.id,
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
        await repo.startRecord(exerciseId: exercise);

        expect(
          await runningPracticeLocation(repo),
          "/practice/exercises/$exercise/play",
        );
      },
    );

    test("nothing is reopened without a running stopwatch", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(record, stop: true);

      expect(await runningPracticeLocation(repo), isNull);
    });

    test("a deleted exercise is settled instead of reopened", () async {
      final exercise = await createExercise("Scales");
      final record = await repo.startRecord(exerciseId: exercise);
      await repo.checkpointRecord(
        record,
        now: record.runningSince!.add(const Duration(minutes: 2)),
      );
      await repo.deleteExercise(exercise);

      expect(await runningPracticeLocation(repo), isNull);
      final settled = (await allRecords()).single;
      expect(settled.runningSince, isNull);
      expect(settled.duration, const Duration(minutes: 2));
    });

    test("a routine that is gone settles its stopwatch", () async {
      final exercise = await createExercise("Scales");
      final routine = await createRoutine("Morning", {
        exercise: const Duration(minutes: 5),
      });
      final record = await repo.startRecord(
        exerciseId: exercise,
        routineId: routine.id,
        routineEntryId: routine.entries.first.id,
      );
      await repo.checkpointRecord(
        record,
        now: record.runningSince!.add(const Duration(minutes: 2)),
      );
      await repo.deleteRoutine(routine.id);

      expect(await runningPracticeLocation(repo), isNull);
      expect(await repo.getRunningRecord(), isNull);
      expect((await allRecords()).single.duration, const Duration(minutes: 2));
    });
  });
}
