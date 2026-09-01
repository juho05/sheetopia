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
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/routine_play_viewmodel.dart';

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

  Future<void> insertScore(String id, {bool downloaded = true}) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileDownloaded: downloaded,
        fileType: FileType.pdf,
        type: const Value(ScoreType.exercise),
      ),
    );
  }

  Future<String> createExercise(String name, List<String> scoreIds) {
    return repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
      scoreIds: scoreIds,
    );
  }

  Future<List<PracticeRoutineEntry>> entriesFor(
    List<String> exerciseIds,
  ) async {
    final exercises = await repo.getExercisesById(exerciseIds);
    return [
      for (final exerciseId in exerciseIds)
        PracticeRoutineEntry(
          id: repo.newRoutineEntryId(),
          exercise: exercises[exerciseId]!,
        ),
    ];
  }

  Future<String> createRoutine(String name, List<String> exerciseIds) async {
    return repo.createRoutine(
      name: name,
      description: "",
      entries: await entriesFor(exerciseIds),
    );
  }

  Future<RoutinePlayViewModel> viewModelFor(
    String routineId, {
    int? startIndex,
  }) async {
    final viewModel = RoutinePlayViewModel(
      repo: repo,
      scoresRepo: scoresRepo,
      routineId: routineId,
      startIndex: startIndex,
    );
    await pumpEventQueue();
    return viewModel;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("routine_play_test");
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

  test("starts on the first playable exercise", () async {
    await insertScore("a", downloaded: false);
    await insertScore("b");
    await insertScore("c");
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b", "c"]);
    final routineId = await createRoutine("Warmup", [scales, arpeggios]);

    final viewModel = await viewModelFor(routineId);

    expect(viewModel.loading, isFalse);
    expect(viewModel.name, "Warmup");
    expect(viewModel.length, 2);
    expect(viewModel.position, 1);
    expect(viewModel.exerciseName, "Arpeggios");
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("a start index opens that exercise", () async {
    await insertScore("a");
    await insertScore("b");
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b"]);
    final routineId = await createRoutine("Warmup", [scales, arpeggios]);

    final viewModel = await viewModelFor(routineId, startIndex: 1);

    expect(viewModel.position, 1);
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("a start index without a playable score falls back", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b"]);
    final routineId = await createRoutine("Warmup", [scales, arpeggios]);

    final viewModel = await viewModelFor(routineId, startIndex: 1);

    expect(viewModel.position, 0);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("next and previous skip exercises without a score", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    await insertScore("c");
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b"]);
    final etude = await createExercise("Etude", ["c"]);
    final routineId = await createRoutine("Warmup", [scales, arpeggios, etude]);

    final viewModel = await viewModelFor(routineId);

    expect(viewModel.hasPrevious, isFalse);
    expect(viewModel.next(), isTrue);
    expect(viewModel.position, 2);
    expect(viewModel.currentScoreId, "c");
    expect(viewModel.hasNext, isFalse);
    expect(viewModel.next(), isFalse);
    expect(viewModel.previous(), isTrue);
    expect(viewModel.position, 0);
    viewModel.dispose();
  });

  test("the neighbouring files are exposed for preloading", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    await insertScore("c");
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b"]);
    final etude = await createExercise("Etude", ["c"]);
    final routineId = await createRoutine("Warmup", [scales, arpeggios, etude]);

    final first = (await scoresRepo.getScore("a"))!.file!.path;
    final last = (await scoresRepo.getScore("c"))!.file!.path;

    final viewModel = await viewModelFor(routineId);

    expect(viewModel.previousFile, isNull);
    expect(viewModel.nextFile?.path, last);

    viewModel.next();

    expect(viewModel.previousFile?.path, first);
    expect(viewModel.nextFile, isNull);
    viewModel.dispose();
  });

  test("the neighbouring file follows the chosen alternative", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    final scales = await createExercise("Scales", ["a"]);
    final etude = await createExercise("Etude", ["b", "c"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final second = (await scoresRepo.getScore("c"))!.file!.path;

    final viewModel = await viewModelFor(routineId);
    viewModel.next();
    viewModel.selectScore(1);
    viewModel.previous();

    expect(viewModel.nextFile?.path, second);
    viewModel.dispose();
  });

  test("selecting a score stays on the same exercise", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    final scales = await createExercise("Scales", ["a", "b"]);
    final etude = await createExercise("Etude", ["c"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final viewModel = await viewModelFor(routineId);
    viewModel.selectScore(1);

    expect(viewModel.position, 0);
    expect(viewModel.scoreIndex, 1);
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("scores that are not downloaded cannot be selected", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    final scales = await createExercise("Scales", ["a", "b"]);
    final routineId = await createRoutine("Warmup", [scales]);

    final viewModel = await viewModelFor(routineId);
    viewModel.selectScore(1);

    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("the selected score is kept per entry", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    final scales = await createExercise("Scales", ["a", "b"]);
    final etude = await createExercise("Etude", ["c"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final viewModel = await viewModelFor(routineId);
    viewModel.selectScore(1);
    viewModel.next();
    viewModel.previous();

    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("the same exercise twice keeps separate selections", () async {
    await insertScore("a");
    await insertScore("b");
    final scales = await createExercise("Scales", ["a", "b"]);
    final routineId = await createRoutine("Warmup", [scales, scales]);

    final viewModel = await viewModelFor(routineId);
    viewModel.selectScore(1);
    viewModel.next();

    expect(viewModel.position, 1);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("a reload keeps the current exercise and its score", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    final scales = await createExercise("Scales", ["a", "b"]);
    final etude = await createExercise("Etude", ["c"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final viewModel = await viewModelFor(routineId);
    viewModel.selectScore(1);
    await repo.updateRoutine(routineId, name: "Evening", description: "");
    await pumpEventQueue();

    expect(viewModel.name, "Evening");
    expect(viewModel.position, 0);
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("removing the current exercise falls back to a nearby one", () async {
    await insertScore("a");
    await insertScore("b");
    final scales = await createExercise("Scales", ["a"]);
    final etude = await createExercise("Etude", ["b"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final viewModel = await viewModelFor(routineId);
    viewModel.next();
    expect(viewModel.position, 1);

    await repo.setRoutineEntries(routineId, await entriesFor([scales]));
    await pumpEventQueue();

    expect(viewModel.length, 1);
    expect(viewModel.position, 0);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("deleting an exercise drops its entry", () async {
    await insertScore("a");
    await insertScore("b");
    final scales = await createExercise("Scales", ["a"]);
    final etude = await createExercise("Etude", ["b"]);
    final routineId = await createRoutine("Warmup", [scales, etude]);

    final viewModel = await viewModelFor(routineId);
    await repo.deleteExercise(scales);
    await pumpEventQueue();

    expect(viewModel.length, 1);
    expect(viewModel.exerciseName, "Etude");
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("the routine being deleted is reported", () async {
    await insertScore("a");
    final scales = await createExercise("Scales", ["a"]);
    final routineId = await createRoutine("Warmup", [scales]);

    final viewModel = await viewModelFor(routineId);
    await repo.deleteRoutine(routineId);
    await pumpEventQueue();

    expect(viewModel.deleted, isTrue);
    viewModel.dispose();
  });

  test("an empty routine has no current score", () async {
    final routineId = await createRoutine("Warmup", []);

    final viewModel = await viewModelFor(routineId);

    expect(viewModel.length, 0);
    expect(viewModel.position, -1);
    expect(viewModel.currentScoreId, isNull);
    viewModel.dispose();
  });
}
