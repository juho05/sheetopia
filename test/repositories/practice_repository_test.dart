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
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<String> insertTag(String name) async {
    final id = db.newId();
    await db.managers.tagsTable.create(
      (o) => o(
        id: id,
        name: name,
        color: 0xFFFF0000,
        type: const Value(TagType.exercise),
      ),
    );
    return id;
  }

  Future<String> insertCategory(String name, {int position = 0}) async {
    final id = db.newId();
    await db.managers.exerciseCategoriesTable.create(
      (o) => o(id: id, name: name, position: position),
    );
    return id;
  }

  Future<String> createExercise(
    String name, {
    String? category,
    String instrument = "",
  }) async {
    final id = await repo.createExercise(
      name: name,
      description: "",
      instrument: instrument,
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

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = PracticeRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test("a created exercise is returned with all its values", () async {
    final tagId = await insertTag("Scales");
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "Up and down",
      instrument: "Guitar",
      source: "Book",
      sourceLink: "https://example.com",
      tagIds: [tagId],
    );

    final exercise = await repo.getExercise(id);
    expect(exercise, isNotNull);
    expect(exercise!.name, "Chromatic");
    expect(exercise.description, "Up and down");
    expect(exercise.instrument, "Guitar");
    expect(exercise.source, "Book");
    expect(exercise.sourceLink, "https://example.com");
    expect(exercise.category, isNull);
    expect(exercise.tags.map((t) => t.id), [tagId]);
  });

  test("empty values are stored as null", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "https://example.com",
      tagIds: const [],
    );

    final exercise = await repo.getExercise(id);
    expect(exercise!.description, isNull);
    expect(exercise.instrument, isNull);
    expect(exercise.source, isNull);
    expect(exercise.sourceLink, isNull);
  });

  test("getExercise returns null for an unknown id", () async {
    expect(await repo.getExercise("missing"), isNull);
  });

  test("getExercise resolves the category", () async {
    final categoryId = await insertCategory("Warmup");
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(category: Value(categoryId)));

    final exercise = await repo.getExercise(id);
    expect(exercise!.category?.name, "Warmup");
  });

  test("updateExercise overwrites the values and clears empty ones", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "Up and down",
      instrument: "Guitar",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );

    await repo.updateExercise(
      id,
      name: "Chromatic scale",
      description: "",
      instrument: "Bass",
    );

    final exercise = await repo.getExercise(id);
    expect(exercise!.name, "Chromatic scale");
    expect(exercise.description, isNull);
    expect(exercise.instrument, "Bass");
  });

  test("updateExerciseSource drops the link without a source", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "Book",
      sourceLink: "https://example.com",
      tagIds: const [],
    );

    await repo.updateExerciseSource(id, source: "", sourceLink: "https://x.de");

    final exercise = await repo.getExercise(id);
    expect(exercise!.source, isNull);
    expect(exercise.sourceLink, isNull);
  });

  test("tags can be added and removed", () async {
    final scales = await insertTag("Scales");
    final warmup = await insertTag("Warmup");
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );

    await repo.addExerciseTags(id, [scales, warmup]);
    // adding a tag twice must not fail
    await repo.addExerciseTags(id, [scales]);
    expect((await repo.getExercise(id))!.tags.map((t) => t.name), [
      "Scales",
      "Warmup",
    ]);

    await repo.removeExerciseTag(id, scales);
    expect((await repo.getExercise(id))!.tags.map((t) => t.name), ["Warmup"]);
  });

  test("editing an exercise marks it as not uploaded", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(uploaded: const Value(true)));

    await repo.addExerciseTags(id, [await insertTag("Scales")]);

    final row = await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .getSingle();
    expect(row.uploaded, isFalse);
  });

  test("a deleted exercise is recorded as deleted", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: [await insertTag("Scales")],
    );

    await repo.deleteExercise(id);

    expect(await repo.getExercise(id), isNull);
    expect(await db.managers.exerciseTagsTable.count(), 0);
    final deleted = await db.managers.deletedExercisesTable.get();
    expect(deleted.map((e) => e.exerciseId), [id]);
  });

  test("deleting an exercise removes its routine entries", () async {
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    final routineId = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: routineId, name: "Morning", uploaded: const Value(true)),
    );
    await db.managers.practiceRoutineEntriesTable.create(
      (o) => o(id: db.newId(), routine: routineId, exercise: id, position: 0),
    );

    await repo.deleteExercise(id);

    expect(await db.managers.practiceRoutineEntriesTable.count(), 0);
    final routine = await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .getSingle();
    expect(routine.uploaded, isFalse);
  });

  test("the remaining routine entries are renumbered", () async {
    Future<String> exercise(String name) => repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
    final first = await exercise("First");
    final removed = await exercise("Removed");
    final last = await exercise("Last");

    final routineId = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: routineId, name: "Morning"),
    );
    // the same exercise may appear more than once in a routine
    for (final (position, exerciseId) in [
      first,
      removed,
      last,
      removed,
    ].indexed) {
      await db.managers.practiceRoutineEntriesTable.create(
        (o) => o(
          id: db.newId(),
          routine: routineId,
          exercise: exerciseId,
          position: position,
        ),
      );
    }

    await repo.deleteExercise(removed);

    final query = db.select(db.practiceRoutineEntriesTable)
      ..where((t) => t.routine.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    final entries = await query.get();
    expect(entries.map((e) => e.position), [0, 1]);
    expect(entries.map((e) => e.exercise), [first, last]);
  });

  test("exercises are grouped by category order, uncategorized last", () async {
    final warmup = await insertCategory("Warmup", position: 1);
    final etudes = await insertCategory("Etudes", position: 0);
    await createExercise("Loose", category: warmup);
    await createExercise("bends", category: warmup);
    await createExercise("Villa-Lobos", category: etudes);
    await createExercise("Uncategorized");

    final exercises = await repo.getExercises(size: 10);
    expect(exercises.map((e) => e.name), [
      "Villa-Lobos",
      "bends",
      "Loose",
      "Uncategorized",
    ]);
    expect(exercises.map((e) => e.category?.name), [
      "Etudes",
      "Warmup",
      "Warmup",
      null,
    ]);
  });

  test("pages do not overlap and end at the last exercise", () async {
    for (var i = 0; i < 5; i++) {
      await createExercise("Exercise $i");
    }

    final first = await repo.getExercises(size: 2);
    final second = await repo.getExercises(size: 2, offset: 2);
    final third = await repo.getExercises(size: 2, offset: 4);
    expect(first.map((e) => e.name), ["Exercise 0", "Exercise 1"]);
    expect(second.map((e) => e.name), ["Exercise 2", "Exercise 3"]);
    expect(third.map((e) => e.name), ["Exercise 4"]);
  });

  test("listed exercises carry their tags", () async {
    final scales = await insertTag("Scales");
    final id = await createExercise("Chromatic");
    await repo.addExerciseTags(id, [scales]);
    await createExercise("Untagged");

    final exercises = await repo.getExercises(size: 10);
    expect(exercises.first.tags.map((t) => t.name), ["Scales"]);
    expect(exercises.last.tags, isEmpty);
  });

  test("the search matches every word of the name", () async {
    await createExercise("Chromatic scale");
    await createExercise("Major scale");

    expect((await repo.getExercises(size: 10, filter: "scale")).length, 2);
    expect((await repo.getExercises(size: 10, filter: "chro scal")).length, 1);
    expect(await repo.countExercises(filter: "chro scal"), 1);
    expect(await repo.countExercises(filter: "  "), 2);
  });

  test("category and instrument filters", () async {
    final warmup = await insertCategory("Warmup", position: 0);
    await createExercise("Bends", category: warmup, instrument: "Guitar");
    await createExercise("Slides", instrument: "Guitar");
    await createExercise("Walking", instrument: "Bass");

    expect((await repo.getExercises(size: 10, category: "Warmup")).length, 1);
    expect(await repo.countExercises(instrument: "Guitar"), 2);
    expect(
      await repo.countExercises(category: "Warmup", instrument: "Bass"),
      0,
    );
  });

  test("tag filters honour the match type", () async {
    final scales = await insertTag("Scales");
    final warmup = await insertTag("Warmup");
    final both = await createExercise("Both");
    await repo.addExerciseTags(both, [scales, warmup]);
    final one = await createExercise("One");
    await repo.addExerciseTags(one, [scales]);
    await createExercise("None");

    Future<List<String>> names(FilterMatchType match) async =>
        (await repo.getExercises(
          size: 10,
          tagIds: [scales],
          tagMatch: match,
        )).map((e) => e.name).toList();

    expect(await names(FilterMatchType.any), ["Both", "One"]);
    expect(await names(FilterMatchType.all), ["Both", "One"]);
    // exact means the exercise carries no other tag
    expect(await names(FilterMatchType.exact), ["One"]);
    expect(
      await repo.countExercises(
        tagIds: [scales, warmup],
        tagMatch: FilterMatchType.all,
      ),
      1,
    );
  });

  test("categories are listed in their own order", () async {
    await insertCategory("Warmup", position: 1);
    await insertCategory("Etudes", position: 0);
    await insertCategory("Technique", position: 2);

    expect(await repo.getCategories(), ["Etudes", "Warmup", "Technique"]);
    expect(await repo.getCategories(size: 2), ["Etudes", "Warmup"]);
    expect(await repo.getCategories(filter: "tud"), ["Etudes"]);
  });

  test("updates are announced to listeners", () async {
    final updates = <Set<String>>[];
    final sub = repo.updatedExerciseIds.listen(updates.add);

    final id = await createExercise("Chromatic");
    await repo.updateExercise(
      id,
      name: "Scale",
      description: "",
      instrument: "",
    );
    await repo.deleteExercise(id);
    await Future.delayed(Duration.zero);
    await sub.cancel();

    expect(updates, [
      {id},
      {id},
      {id},
    ]);
  });

  test("instruments and sources come from exercises and scores", () async {
    await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "guitar",
      source: "Book",
      sourceLink: "",
      tagIds: const [],
    );
    await db.managers.scoresTable.create(
      (o) => o(
        id: "score",
        title: "Etude",
        searchText: "etude",
        fileType: FileType.pdf,
        fileDownloaded: true,
        source: const Value("Archive"),
      ),
    );
    await db.managers.instrumentsTable.create(
      (o) => o(score: "score", instrument: "Bass"),
    );

    expect(await repo.getInstruments(), ["Bass", "guitar"]);
    expect(await repo.getSources(), ["Archive", "Book"]);
    expect(await repo.getInstruments(filter: "gui"), ["guitar"]);
    expect(await repo.getSources(filter: "arc"), ["Archive"]);
  });
}
