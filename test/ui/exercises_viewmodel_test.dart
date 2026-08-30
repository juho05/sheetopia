/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;
  late ExercisesViewModel viewModel;

  Future<String> insertCategory(String name, int position) async {
    final id = db.newId();
    await db.managers.exerciseCategoriesTable.create(
      (o) => o(id: id, name: name, position: position),
    );
    return id;
  }

  Future<String> createExercise(String name, {String? category}) async {
    final id = await repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    if (category != null) {
      await db.managers.exercisesTable
          .filter((f) => f.id(id))
          .update((o) => o(category: Value(category)));
    }
    return id;
  }

  List<String> namesOf(ExercisesViewModel viewModel) => [
    for (final group in viewModel.exercises)
      ...group.exercise.map((e) => e.name),
  ];

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
    viewModel = ExercisesViewModel(repo: repo);
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  test("exercises are grouped by category", () async {
    final warmup = await insertCategory("Warmup", 0);
    await createExercise("Bends", category: warmup);
    await createExercise("Slides", category: warmup);
    await createExercise("Improvising");

    await viewModel.loadNextPage();

    expect(viewModel.exercises.map((g) => g.category?.name), ["Warmup", null]);
    expect(viewModel.exercises.first.exercise.map((e) => e.name), [
      "Bends",
      "Slides",
    ]);
    expect(viewModel.exercises.last.exercise.map((e) => e.name), [
      "Improvising",
    ]);
  });

  test("an empty library has no groups and no next page", () async {
    await viewModel.loadNextPage();

    expect(viewModel.exercises, isEmpty);
    expect(viewModel.hasNextPage, isFalse);
  });

  test("a group spanning two pages is not split", () async {
    final warmup = await insertCategory("Warmup", 0);
    for (var i = 0; i < 250; i++) {
      await createExercise(
        "Exercise ${i.toString().padLeft(3, "0")}",
        category: warmup,
      );
    }

    await viewModel.loadNextPage();
    expect(viewModel.exercises.length, 1);
    expect(viewModel.exercises.first.exercise.length, 100);
    expect(viewModel.hasNextPage, isTrue);

    await viewModel.loadNextPage();
    await viewModel.loadNextPage();

    expect(viewModel.exercises.length, 1);
    expect(viewModel.exercises.first.exercise.length, 250);
    expect(viewModel.hasNextPage, isFalse);
    expect(namesOf(viewModel).first, "Exercise 000");
    expect(namesOf(viewModel).last, "Exercise 249");
  });

  test("concurrent calls load the page only once", () async {
    for (var i = 0; i < 3; i++) {
      await createExercise("Exercise $i");
    }

    await Future.wait([viewModel.loadNextPage(), viewModel.loadNextPage()]);

    expect(namesOf(viewModel).length, 3);
  });

  test("a repository update reloads the loaded pages", () async {
    final id = await createExercise("Chromatic");
    await viewModel.loadNextPage();
    expect(namesOf(viewModel), ["Chromatic"]);

    await repo.updateExercise(
      id,
      name: "Chromatic scale",
      description: "",
      instrument: "",
    );
    await Future.delayed(Duration.zero);

    expect(namesOf(viewModel), ["Chromatic scale"]);
  });

  test("a deleted exercise disappears from the list", () async {
    final id = await createExercise("Chromatic");
    await createExercise("Bends");
    await viewModel.loadNextPage();

    await repo.deleteExercise(id);
    await Future.delayed(Duration.zero);

    expect(namesOf(viewModel), ["Bends"]);
  });

  test("the counts follow the filters", () async {
    await createExercise("Chromatic scale");
    await createExercise("Bends");
    await viewModel.loadNextPage();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(viewModel.totalCount, 2);
    expect(viewModel.resultCount, 2);

    viewModel.filterSearch = "scale";
    await Future.delayed(const Duration(milliseconds: 350));

    expect(viewModel.totalCount, 2);
    expect(viewModel.resultCount, 1);
  });

  test("loading is only true until the first page arrives", () async {
    await createExercise("Chromatic");

    expect(viewModel.loading, isTrue);
    await viewModel.loadNextPage();

    expect(viewModel.loading, isFalse);
  });

  test("filters are applied after the debounce", () async {
    await createExercise("Chromatic scale");
    await createExercise("Bends");
    await viewModel.loadNextPage();

    viewModel.filterSearch = "scale";
    expect(namesOf(viewModel), ["Bends", "Chromatic scale"]);

    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Chromatic scale"]);
    expect(viewModel.isFiltered, isTrue);
    expect(viewModel.hasFilters, isFalse);
  });

  test("clearing the filters restores every exercise", () async {
    await createExercise("Chromatic scale");
    await createExercise("Bends");
    await viewModel.loadNextPage();

    viewModel.filterInstrument = "Guitar";
    await Future.delayed(const Duration(milliseconds: 300));
    expect(namesOf(viewModel), isEmpty);
    expect(viewModel.hasFilters, isTrue);

    viewModel.clearFilters();
    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Bends", "Chromatic scale"]);
  });
}
