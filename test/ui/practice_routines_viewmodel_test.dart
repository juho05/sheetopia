/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:ui';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;
  late PracticeRoutinesViewModel viewModel;

  Future<Tag> insertTag(String name) async {
    final id = db.newId();
    final tag = await db.managers.tagsTable.createReturning(
      (o) => o(
        id: id,
        name: name,
        color: 0xFFFF0000,
        type: const Value(TagType.exercise),
      ),
    );
    return Tag(
      id: tag.id,
      name: tag.name,
      color: const Color(0xFFFF0000),
      type: tag.type,
      updatedAt: tag.updatedAt.toUtc(),
    );
  }

  Future<String> createExercise(
    String name, {
    String instrument = "",
    Iterable<String> tagIds = const [],
  }) => repo.createExercise(
    name: name,
    description: "",
    instrument: instrument,
    source: "",
    sourceLink: "",
    tagIds: tagIds,
  );

  Future<String> createRoutine(
    String name, {
    List<String> exercises = const [],
  }) async {
    final id = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: id, name: name),
    );
    for (final (position, exercise) in exercises.indexed) {
      await db.managers.practiceRoutineEntriesTable.create(
        (o) => o(
          id: db.newId(),
          routine: id,
          exercise: exercise,
          position: position,
          targetDuration: const Value(Duration(minutes: 5)),
        ),
      );
    }
    return id;
  }

  List<String> namesOf(PracticeRoutinesViewModel viewModel) =>
      viewModel.routines.map((r) => r.name).toList();

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
    viewModel = PracticeRoutinesViewModel(repo: repo);
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  test("routines are listed with their entries", () async {
    final exercise = await createExercise("Chromatic");
    await createRoutine("Morning", exercises: [exercise, exercise]);
    await createRoutine("Evening");

    await viewModel.loadNextPage();

    expect(namesOf(viewModel), ["Evening", "Morning"]);
    expect(viewModel.routines.last.exerciseCount, 2);
    expect(viewModel.routines.last.targetDuration, const Duration(minutes: 10));
  });

  test("an empty library has no routines and no next page", () async {
    await viewModel.loadNextPage();

    expect(viewModel.routines, isEmpty);
    expect(viewModel.hasNextPage, isFalse);
    expect(viewModel.loading, isFalse);
  });

  test("concurrent calls load the page only once", () async {
    await createRoutine("Morning");

    await Future.wait([viewModel.loadNextPage(), viewModel.loadNextPage()]);

    expect(namesOf(viewModel), ["Morning"]);
  });

  test("an exercise update reloads the loaded pages", () async {
    final exercise = await createExercise("Chromatic");
    await createRoutine("Morning", exercises: [exercise]);
    await viewModel.loadNextPage();

    await repo.deleteExercise(exercise);
    await Future.delayed(Duration.zero);

    expect(viewModel.routines.single.exerciseCount, 0);
  });

  test("the counts follow the filters", () async {
    final guitar = await createExercise("Chromatic", instrument: "Guitar");
    await createRoutine("Morning", exercises: [guitar]);
    await createRoutine("Evening");
    // the counts are refreshed on repository updates, so a viewmodel created
    // before the routines exist would still report the old totals
    viewModel.dispose();
    viewModel = PracticeRoutinesViewModel(repo: repo);
    await viewModel.loadNextPage();
    await Future.delayed(const Duration(milliseconds: 50));

    expect(viewModel.totalCount, 2);
    expect(viewModel.resultCount, 2);

    viewModel.filterInstrument = "Guitar";
    await Future.delayed(const Duration(milliseconds: 350));

    expect(viewModel.totalCount, 2);
    expect(viewModel.resultCount, 1);
    expect(namesOf(viewModel), ["Morning"]);
  });

  test("filters are applied after the debounce", () async {
    await createRoutine("Morning warm up");
    await createRoutine("Evening");
    await viewModel.loadNextPage();

    viewModel.filterSearch = "morning";
    expect(namesOf(viewModel), ["Evening", "Morning warm up"]);

    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Morning warm up"]);
    expect(viewModel.isFiltered, isTrue);
    expect(viewModel.hasFilters, isFalse);
  });

  test("tag filters match the exercises of a routine", () async {
    final scales = await insertTag("Scales");
    final warmup = await insertTag("Warmup");
    final scalesExercise = await createExercise(
      "Chromatic",
      tagIds: [scales.id],
    );
    final warmupExercise = await createExercise(
      "Long tones",
      tagIds: [warmup.id],
    );
    await createRoutine("Both", exercises: [scalesExercise, warmupExercise]);
    await createRoutine("Only scales", exercises: [scalesExercise]);
    await viewModel.loadNextPage();

    viewModel.addFilterTags([scales, warmup]);
    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Both"]);
    expect(viewModel.hasFilters, isTrue);

    viewModel.tagMatch = FilterMatchType.any;
    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Both", "Only scales"]);
  });

  test("clearing the filters restores every routine", () async {
    await createRoutine("Morning");
    await createRoutine("Evening");
    await viewModel.loadNextPage();

    viewModel.filterInstrument = "Guitar";
    await Future.delayed(const Duration(milliseconds: 300));
    expect(namesOf(viewModel), isEmpty);

    viewModel.clearFilters();
    await Future.delayed(const Duration(milliseconds: 300));

    expect(namesOf(viewModel), ["Evening", "Morning"]);
  });

  test("the instrument options come from routines", () async {
    final guitar = await createExercise("Chromatic", instrument: "Guitar");
    await createExercise("Unused", instrument: "Bass");
    await createRoutine("Morning", exercises: [guitar]);

    expect(await viewModel.getInstruments(), ["Guitar"]);
  });
}
