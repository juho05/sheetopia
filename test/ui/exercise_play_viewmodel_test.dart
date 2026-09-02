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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/exercise_play_viewmodel.dart';

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

  // a load resolves score files from the file system, pumpEventQueue can return
  // before that lands and leave the view model half loaded
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 2000 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(done(), isTrue, reason: "timed out waiting for the view model");
  }

  Future<ExercisePlayViewModel> viewModelFor(String exerciseId) async {
    final viewModel = ExercisePlayViewModel(
      repo: repo,
      scoresRepo: scoresRepo,
      exerciseId: exerciseId,
    );
    await waitFor(() => !viewModel.loading);
    return viewModel;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("exercise_play_test");
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

  test("starts on the first playable score", () async {
    await insertScore("a", downloaded: false);
    await insertScore("b");
    final exerciseId = await createExercise("Scales", ["a", "b"]);

    final viewModel = await viewModelFor(exerciseId);

    expect(viewModel.loading, isFalse);
    expect(viewModel.exerciseName, "Scales");
    expect(viewModel.scores.map((s) => s.id), ["a", "b"]);
    expect(viewModel.position, 1);
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("selecting switches to another score of the exercise", () async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Scales", ["a", "b"]);

    final viewModel = await viewModelFor(exerciseId);
    viewModel.selectScore(1);

    expect(viewModel.position, 1);
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });

  test("scores that are not downloaded cannot be selected", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    final exerciseId = await createExercise("Scales", ["a", "b"]);

    final viewModel = await viewModelFor(exerciseId);
    viewModel.selectScore(1);

    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("removing the selected score falls back to another one", () async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Scales", ["a", "b"]);

    final viewModel = await viewModelFor(exerciseId);
    viewModel.selectScore(1);
    await repo.setExerciseScores(exerciseId, ["a"]);
    await waitFor(() => viewModel.scores.length == 1);

    expect(viewModel.scores.map((s) => s.id), ["a"]);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("the exercise being deleted is reported", () async {
    await insertScore("a");
    final exerciseId = await createExercise("Scales", ["a"]);

    final viewModel = await viewModelFor(exerciseId);
    await repo.deleteExercise(exerciseId);
    await waitFor(() => viewModel.deleted);

    expect(viewModel.deleted, isTrue);
    viewModel.dispose();
  });

  test("a reload keeps the selected copy of a repeated score", () async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Scales", ["a", "b", "a"]);

    final viewModel = await viewModelFor(exerciseId);
    viewModel.selectScore(2);
    expect(viewModel.position, 2);

    var loads = 0;
    viewModel.addListener(() => loads++);
    await scoresRepo.saveAnnotations("a", const {});
    await waitFor(() => loads > 0);

    expect(viewModel.scores.map((s) => s.id), ["a", "b", "a"]);
    expect(viewModel.position, 2);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("dropping the selected copy falls back to a remaining one", () async {
    await insertScore("a");
    await insertScore("b");
    final exerciseId = await createExercise("Scales", ["a", "b", "a"]);

    final viewModel = await viewModelFor(exerciseId);
    viewModel.selectScore(2);
    await repo.setExerciseScores(exerciseId, ["b", "a"]);
    await waitFor(() => viewModel.scores.map((s) => s.id).join() == "ba");

    expect(viewModel.scores.map((s) => s.id), ["b", "a"]);
    expect(viewModel.position, 1);
    expect(viewModel.currentScoreId, "a");
    viewModel.dispose();
  });

  test("showing another exercise starts at its first score", () async {
    await insertScore("a");
    await insertScore("b");
    final scales = await createExercise("Scales", ["a"]);
    final arpeggios = await createExercise("Arpeggios", ["b"]);

    final viewModel = await viewModelFor(scales);
    await viewModel.showExercise(arpeggios);

    expect(viewModel.exerciseName, "Arpeggios");
    expect(viewModel.currentScoreId, "b");
    viewModel.dispose();
  });
}
