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
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
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

  Future<List<String>> categoryNames() async =>
      (await repo.getAllCategories()).map((c) => c.name).toList();

  Future<void> insertScore(
    String id, {
    ScoreType type = ScoreType.score,
  }) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileType: FileType.pdf,
        fileDownloaded: true,
        type: Value(type),
      ),
    );
  }

  Future<List<(String, int)>> scoreEntries(String exerciseId) async {
    final query = db.select(db.exerciseScoresTable)
      ..where((t) => t.exercise.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return (await query.get()).map((e) => (e.score, e.position)).toList();
  }

  Future<PracticeRoutineEntry> entry(
    String exerciseId, {
    Duration? targetDuration,
    String? defaultScoreId,
  }) async => PracticeRoutineEntry(
    id: repo.newRoutineEntryId(),
    exercise: (await repo.getExercisesById([exerciseId]))[exerciseId]!,
    targetDuration: targetDuration,
    defaultScoreId: defaultScoreId,
  );

  Future<List<(String, String, int)>> entryRows(String routineId) async {
    final query = db.select(db.practiceRoutineEntriesTable)
      ..where((t) => t.routine.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return (await query.get())
        .map((e) => (e.id, e.exercise, e.position))
        .toList();
  }

  Future<String> createRoutine(String name) async {
    final id = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: id, name: name),
    );
    return id;
  }

  Future<void> addEntry(
    String routineId,
    String exerciseId, {
    int position = 0,
    Duration? targetDuration,
  }) async {
    await db.managers.practiceRoutineEntriesTable.create(
      (o) => o(
        id: db.newId(),
        routine: routineId,
        exercise: exerciseId,
        position: position,
        targetDuration: Value(targetDuration),
      ),
    );
  }

  Future<List<String>> routineNames({
    int size = 100,
    int offset = 0,
    String filter = "",
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async => (await repo.getRoutines(
    size: size,
    offset: offset,
    filter: filter,
    instrument: instrument,
    tagIds: tagIds,
    tagMatch: tagMatch,
  )).map((r) => r.name).toList();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("practice_test");
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

    expect((await repo.getExercises(size: 10, categoryId: warmup)).length, 1);
    expect(await repo.countExercises(instrument: "Guitar"), 2);
    expect(
      await repo.countExercises(categoryId: warmup, instrument: "Bass"),
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

    expect(await categoryNames(), ["Etudes", "Warmup", "Technique"]);
  });

  test("an exercise can be created with a category", () async {
    final warmup = await repo.createCategory("Warmup");

    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
      categoryId: warmup.id,
    );

    expect((await repo.getExercise(id))?.category?.id, warmup.id);
  });

  test("the category of an exercise can be changed and removed", () async {
    final warmup = await repo.createCategory("Warmup");
    final id = await createExercise("Chromatic");
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(uploaded: const Value(true)));

    await repo.updateExerciseCategory(id, warmup.id);

    expect((await repo.getExercise(id))?.category?.name, "Warmup");
    final updated = await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .getSingle();
    expect(updated.uploaded, isFalse);

    await repo.updateExerciseCategory(id, null);

    expect((await repo.getExercise(id))?.category, isNull);
  });

  test("categories are created at the end and can be reordered", () async {
    final warmup = await repo.createCategory("Warmup");
    final etudes = await repo.createCategory("Etudes");
    final technique = await repo.createCategory("Technique");

    expect(await categoryNames(), ["Warmup", "Etudes", "Technique"]);

    await repo.moveCategory(2, 0);

    expect((await repo.getAllCategories()).map((c) => c.id), [
      technique.id,
      warmup.id,
      etudes.id,
    ]);

    await repo.moveCategory(0, 3);

    expect(await categoryNames(), ["Technique", "Warmup", "Etudes"]);
  });

  test("a renamed category is reported with the exercise", () async {
    final warmup = await repo.createCategory("Warmup");
    final id = await createExercise("Chromatic", category: warmup.id);

    await repo.renameCategory(warmup.id, "Warm up");

    expect((await repo.getExercise(id))?.category?.name, "Warm up");
  });

  test("deleting a category detaches its exercises", () async {
    final warmup = await repo.createCategory("Warmup");
    final etudes = await repo.createCategory("Etudes");
    final id = await createExercise("Chromatic", category: warmup.id);
    final updates = <Set<String>>[];
    final sub = repo.updatedExerciseIds.listen(updates.add);

    await repo.deleteCategory(warmup.id);
    await Future.delayed(Duration.zero);
    await sub.cancel();

    expect((await repo.getExercise(id))?.category, isNull);
    expect(updates.last, {id});
    final remaining = await db.managers.exerciseCategoriesTable.get();
    expect(remaining.map((c) => c.id), [etudes.id]);
    // the survivors close the gap left behind
    expect(remaining.single.position, 0);
    expect(
      (await db.managers.deletedExerciseCategoriesTable.get()).map(
        (c) => c.categoryId,
      ),
      [warmup.id],
    );
  });

  test("exercises are counted per category", () async {
    final warmup = await repo.createCategory("Warmup");
    await repo.createCategory("Etudes");
    await createExercise("Chromatic", category: warmup.id);
    await createExercise("Bends", category: warmup.id);
    await createExercise("Slides");

    // empty categories are left out
    expect(await repo.countExercisesPerCategory(), {warmup.id: 2});
  });

  test("category updates are announced to listeners", () async {
    final updates = <Set<String>>[];
    final sub = repo.updatedCategoryIds.listen(updates.add);

    final category = await repo.createCategory("Warmup");
    await repo.renameCategory(category.id, "Warm up");
    await repo.deleteCategory(category.id);
    await Future.delayed(Duration.zero);
    await sub.cancel();

    expect(updates, [
      {category.id},
      {category.id},
      {category.id},
    ]);
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

  test("scores linked at creation are stored in order", () async {
    await insertScore("a");
    await insertScore("b");
    final id = await repo.createExercise(
      name: "Chromatic",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
      scoreIds: const ["b", "a"],
    );

    expect(await repo.getExerciseScoreIds(id), ["b", "a"]);
    expect(await scoreEntries(id), [("b", 0), ("a", 1)]);
  });

  test("the scores of an exercise are loaded in order", () async {
    await insertScore("a");
    await insertScore("b");
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["b", "a"]);

    final scores = await repo.getExerciseScores(id);

    expect(scores.map((s) => s.id), ["b", "a"]);
    expect(scores.map((s) => s.title), ["Title b", "Title a"]);
    expect(scores.every((s) => s.file != null), isTrue);

    await repo.setExerciseScores(id, ["a", "a"]);
    expect((await repo.getExerciseScores(id)).map((s) => s.id), ["a", "a"]);
  });

  test("set scores are stored in the given order", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    final id = await createExercise("Chromatic");

    await repo.setExerciseScores(id, ["a", "b", "c"]);
    expect(await scoreEntries(id), [("a", 0), ("b", 1), ("c", 2)]);

    await repo.setExerciseScores(id, ["c", "a"]);
    expect(await repo.getExerciseScoreIds(id), ["c", "a"]);
    expect(await scoreEntries(id), [("c", 0), ("a", 1)]);
  });

  test("setting scores marks the exercise as not uploaded", () async {
    await insertScore("a");
    final id = await createExercise("Chromatic");
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(uploaded: const Value(true)));

    await repo.setExerciseScores(id, ["a"]);

    final row = await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .getSingle();
    expect(row.uploaded, isFalse);
  });

  test("entries of scores missing locally are not returned", () async {
    await insertScore("a");
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["a", "missing"]);

    expect(await repo.getExerciseScoreIds(id), ["a"]);
  });

  test("the same score can be linked more than once", () async {
    await insertScore("a");
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["a", "a"]);

    expect(await repo.getExerciseScoreIds(id), ["a", "a"]);
  });

  test("unlinking an owned score deletes it", () async {
    await insertScore("linked");
    await insertScore("owned", type: ScoreType.exercise);
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["linked", "owned"]);

    await repo.setExerciseScores(id, ["linked"]);

    expect(
      await db.managers.scoresTable.filter((f) => f.id("owned")).exists(),
      isFalse,
    );
    expect(
      await db.managers.scoresTable.filter((f) => f.id("linked")).exists(),
      isTrue,
    );
    expect((await db.managers.deletedScoresTable.get()).map((d) => d.scoreId), [
      "owned",
    ]);
  });

  test("unlinking a score of an unknown type keeps it", () async {
    await insertScore("future", type: ScoreType.byName("from-the-future"));
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["future"]);

    await repo.setExerciseScores(id, []);

    expect(
      await db.managers.scoresTable.filter((f) => f.id("future")).exists(),
      isTrue,
    );
    expect(await db.managers.deletedScoresTable.get(), isEmpty);
  });

  test("an owned score kept in the list survives a reorder", () async {
    await insertScore("a");
    await insertScore("owned", type: ScoreType.exercise);
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["a", "owned"]);

    await repo.setExerciseScores(id, ["owned", "a"]);

    expect(await repo.getExerciseScoreIds(id), ["owned", "a"]);
    expect(
      await db.managers.scoresTable.filter((f) => f.id("owned")).exists(),
      isTrue,
    );
  });

  test("deleting an exercise removes its entries and owned scores", () async {
    await insertScore("linked");
    await insertScore("owned", type: ScoreType.exercise);
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["linked", "owned"]);

    await repo.deleteExercise(id);

    expect(await scoreEntries(id), isEmpty);
    expect(
      await db.managers.scoresTable.filter((f) => f.id("owned")).exists(),
      isFalse,
    );
    expect(
      await db.managers.scoresTable.filter((f) => f.id("linked")).exists(),
      isTrue,
    );
  });

  test("deleting a linked score removes its entries", () async {
    await insertScore("a");
    await insertScore("b");
    final id = await createExercise("Chromatic");
    final other = await createExercise("Scales");
    await repo.setExerciseScores(id, ["a", "b"]);
    await repo.setExerciseScores(other, ["b"]);
    await db.managers.exercisesTable
        .filter((f) => f.id.isIn([id, other]))
        .update((o) => o(uploaded: const Value(true)));

    final updated = <Set<String>>[];
    // the stream replays the event of the last setExerciseScores call
    final sub = repo.updatedExerciseIds.skip(1).listen(updated.add);
    await repo.removeDeletedScoreEntries({"b"});
    await Future.delayed(Duration.zero);
    await sub.cancel();

    expect(await repo.getExerciseScoreIds(id), ["a"]);
    expect(await repo.getExerciseScoreIds(other), isEmpty);
    expect(updated, [
      {id, other},
    ]);
    final rows = await db.managers.exercisesTable
        .filter((f) => f.id.isIn([id, other]))
        .get();
    expect(rows.every((e) => !e.uploaded), isTrue);
  });

  test("deleting an unrelated score leaves the exercise untouched", () async {
    await insertScore("a");
    await insertScore("b");
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["a"]);
    await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .update((o) => o(uploaded: const Value(true)));

    await repo.removeDeletedScoreEntries({"b"});

    expect(await repo.getExerciseScoreIds(id), ["a"]);
    final row = await db.managers.exercisesTable
        .filter((f) => f.id(id))
        .getSingle();
    expect(row.uploaded, isTrue);
  });

  test("deleting a score from the library prunes its entries", () async {
    await insertScore("a");
    await insertScore("b");
    final id = await createExercise("Chromatic");
    await repo.setExerciseScores(id, ["a", "b"]);

    await scoresRepo.deleteScore("b");
    await Future.delayed(Duration.zero);

    expect(await scoreEntries(id), [("a", 0)]);
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

  test("routines are listed by name with their entry count", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final morning = await createRoutine("Morning");
    final evening = await createRoutine("Evening");
    await addEntry(morning, first, targetDuration: const Duration(minutes: 5));
    await addEntry(
      morning,
      second,
      position: 1,
      targetDuration: const Duration(minutes: 10),
    );
    await addEntry(evening, first);

    final routines = await repo.getRoutines(size: 10);

    expect(routines.map((r) => r.name), ["Evening", "Morning"]);
    expect(routines.map((r) => r.exerciseCount), [1, 2]);
    expect(routines.map((r) => r.targetDuration), [
      Duration.zero,
      const Duration(minutes: 15),
    ]);
    expect(routines.map((r) => r.id), [evening, morning]);
    expect(await repo.countRoutines(), 2);
  });

  test("a routine without entries is listed", () async {
    await createRoutine("Empty");

    final routines = await repo.getRoutines(size: 10);

    expect(routines.single.exerciseCount, 0);
    expect(routines.single.targetDuration, Duration.zero);
  });

  test("routine pages do not overlap and end at the last routine", () async {
    for (final name in ["A", "B", "C"]) {
      await createRoutine(name);
    }

    expect(await routineNames(size: 2), ["A", "B"]);
    expect(await routineNames(size: 2, offset: 2), ["C"]);
    expect(await routineNames(size: 2, offset: 4), isEmpty);
  });

  test("the routine search matches every word of the name", () async {
    await createRoutine("Morning warm up");
    await createRoutine("Evening warm up");

    expect(await routineNames(filter: "warm morning"), ["Morning warm up"]);
    expect(await routineNames(filter: "warm"), [
      "Evening warm up",
      "Morning warm up",
    ]);
    expect(await routineNames(filter: "scales"), isEmpty);
    expect(await repo.countRoutines(filter: "warm morning"), 1);
  });

  test("the instrument filter looks at the exercises of a routine", () async {
    final guitar = await createExercise("Chromatic", instrument: "Guitar");
    final piano = await createExercise("Thirds", instrument: "Piano");
    final mixed = await createRoutine("Mixed");
    final pianoOnly = await createRoutine("Piano only");
    await createRoutine("Empty");
    await addEntry(mixed, guitar);
    await addEntry(mixed, piano, position: 1);
    await addEntry(pianoOnly, piano);

    expect(await routineNames(instrument: "Guitar"), ["Mixed"]);
    expect(await routineNames(instrument: "Piano"), ["Mixed", "Piano only"]);
    expect(await routineNames(instrument: "Bass"), isEmpty);
    expect(await repo.countRoutines(instrument: "Piano"), 2);
  });

  test("routine tag filters honour the match type", () async {
    final scales = await insertTag("Scales");
    final warmup = await insertTag("Warmup");
    final etude = await insertTag("Etude");
    final scalesExercise = await createExercise("Chromatic");
    final warmupExercise = await createExercise("Long tones");
    final etudeExercise = await createExercise("Etude no. 1");
    await repo.addExerciseTags(scalesExercise, [scales]);
    await repo.addExerciseTags(warmupExercise, [warmup]);
    await repo.addExerciseTags(etudeExercise, [etude]);

    // the tags of a routine are the tags of all its exercises together
    final both = await createRoutine("Both");
    await addEntry(both, scalesExercise);
    await addEntry(both, warmupExercise, position: 1);
    final onlyScales = await createRoutine("Only scales");
    await addEntry(onlyScales, scalesExercise);
    final extra = await createRoutine("Extra");
    await addEntry(extra, scalesExercise);
    await addEntry(extra, warmupExercise, position: 1);
    await addEntry(extra, etudeExercise, position: 2);

    expect(
      await routineNames(
        tagIds: [scales, warmup],
        tagMatch: FilterMatchType.any,
      ),
      ["Both", "Extra", "Only scales"],
    );
    expect(
      await routineNames(
        tagIds: [scales, warmup],
        tagMatch: FilterMatchType.all,
      ),
      ["Both", "Extra"],
    );
    expect(
      await routineNames(
        tagIds: [scales, warmup],
        tagMatch: FilterMatchType.exact,
      ),
      ["Both"],
    );
    expect(
      await repo.countRoutines(
        tagIds: [scales, warmup],
        tagMatch: FilterMatchType.exact,
      ),
      1,
    );
  });

  test("routine filters are combined", () async {
    final scales = await insertTag("Scales");
    final guitar = await createExercise("Chromatic", instrument: "Guitar");
    final piano = await createExercise("Thirds", instrument: "Piano");
    await repo.addExerciseTags(guitar, [scales]);
    await repo.addExerciseTags(piano, [scales]);
    final morning = await createRoutine("Morning guitar");
    final evening = await createRoutine("Evening piano");
    await addEntry(morning, guitar);
    await addEntry(evening, piano);

    expect(await routineNames(filter: "morning", instrument: "Guitar"), [
      "Morning guitar",
    ]);
    expect(await routineNames(filter: "morning", instrument: "Piano"), isEmpty);
    expect(await routineNames(instrument: "Piano", tagIds: [scales]), [
      "Evening piano",
    ]);
  });

  test("deleting an exercise announces its routines", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await createRoutine("Morning");
    await addEntry(routineId, exerciseId);

    final announced = repo.updatedRoutineIds.first;
    await repo.deleteExercise(exerciseId);

    expect(await announced, {routineId});
  });

  test("a created routine is returned with its entries", () async {
    final first = await createExercise("Chromatic", instrument: "Guitar");
    final second = await createExercise("Thirds");
    final entries = [
      await entry(first, targetDuration: const Duration(minutes: 5)),
      await entry(second),
      // the same exercise may be added more than once
      await entry(first, targetDuration: const Duration(minutes: 10)),
    ];

    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: entries,
    );
    final routine = await repo.getRoutine(routineId);

    expect(routine, isNotNull);
    expect(routine!.name, "Morning");
    expect(routine.description, "Every day");
    expect(routine.exerciseCount, 3);
    expect(routine.targetDuration, const Duration(minutes: 15));
    expect(routine.entries.map((e) => e.id), entries.map((e) => e.id));
    expect(routine.entries.map((e) => e.exercise.name), [
      "Chromatic",
      "Thirds",
      "Chromatic",
    ]);
    expect(routine.entries.first.exercise.instrument, "Guitar");
  });

  test("an empty description is stored as null", () async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    expect((await repo.getRoutine(routineId))!.description, isNull);
  });

  test("getRoutine returns null for an unknown id", () async {
    expect(await repo.getRoutine("nope"), isNull);
  });

  test(
    "updateRoutine overwrites the values and clears the description",
    () async {
      final routineId = await repo.createRoutine(
        name: "Morning",
        description: "Every day",
      );

      await repo.updateRoutine(routineId, name: "Evening", description: "");

      final routine = await repo.getRoutine(routineId);
      expect(routine!.name, "Evening");
      expect(routine.description, isNull);
      final row = await db.managers.practiceRoutinesTable
          .filter((f) => f.id(routineId))
          .getSingle();
      expect(row.uploaded, isFalse);
    },
  );

  test("reordered entries keep their ids", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final entries = [await entry(first), await entry(second)];
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: entries,
    );

    await repo.setRoutineEntries(routineId, entries.reversed.toList());

    expect(await entryRows(routineId), [
      (entries[1].id, second, 0),
      (entries[0].id, first, 1),
    ]);
  });

  test("setRoutineEntries adds and removes entries", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final kept = await entry(first);
    final removed = await entry(second);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [kept, removed],
    );
    final added = await entry(second, targetDuration: const Duration(hours: 1));

    await repo.setRoutineEntries(routineId, [kept, added]);

    expect(await entryRows(routineId), [
      (kept.id, first, 0),
      (added.id, second, 1),
    ]);
    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.last.targetDuration, const Duration(hours: 1));
    expect(routine.targetDuration, const Duration(hours: 1));
  });

  test("all entries can be removed", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await repo.setRoutineEntries(routineId, []);

    expect(await entryRows(routineId), isEmpty);
    expect((await repo.getRoutine(routineId))!.entries, isEmpty);
  });

  test("the default score of an entry is returned", () async {
    final exerciseId = await createExercise("Chromatic");
    await insertScore("a");
    await insertScore("b");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "b")],
    );

    final routine = await repo.getRoutine(routineId);

    expect(routine!.entries.single.defaultScoreId, "b");
  });

  test("a default score that is not available locally is kept", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "elsewhere")],
    );

    final routine = await repo.getRoutine(routineId);

    expect(routine!.entries.single.defaultScoreId, "elsewhere");
  });

  test("setRoutineEntries writes the default score", () async {
    final exerciseId = await createExercise("Chromatic");
    await insertScore("a");
    await insertScore("b");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );
    final existing = (await repo.getRoutine(routineId))!.entries.single;

    await repo.setRoutineEntries(routineId, [
      existing.withDefaultScore(
        (await repo.getExerciseScores(exerciseId)).last,
      ),
    ]);

    expect(
      (await repo.getRoutine(routineId))!.entries.single.defaultScoreId,
      "b",
    );

    await repo.setRoutineEntries(routineId, [existing.withDefaultScore(null)]);

    expect(
      (await repo.getRoutine(routineId))!.entries.single.defaultScoreId,
      isNull,
    );
  });

  test("setRoutineEntries keeps the notes it does not know about", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );
    await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(routineId))
        .update((o) => o(extraNotes: const Value("Slowly")));
    final existing = (await repo.getRoutine(routineId))!.entries.single;

    await repo.setRoutineEntries(routineId, [
      existing.withTargetDuration(const Duration(minutes: 5)),
    ]);

    final row = await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(routineId))
        .getSingle();
    expect(row.extraNotes, "Slowly");
    expect(row.targetDuration, const Duration(minutes: 5));
  });

  test("deleting a score clears it as a routine entry default", () async {
    final exerciseId = await createExercise("Chromatic");
    await insertScore("a");
    await insertScore("b");
    await repo.setExerciseScores(exerciseId, ["a", "b"]);
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId, defaultScoreId: "b")],
    );
    await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .update((o) => o(uploaded: const Value(true)));

    await scoresRepo.deleteScores({"b"});

    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.single.defaultScoreId, isNull);
    final row = await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .getSingle();
    expect(row.uploaded, isFalse);
  });

  test("changing the entries marks the routine as not uploaded", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .update((o) => o(uploaded: const Value(true)));

    await repo.setRoutineEntries(routineId, [await entry(exerciseId)]);

    final row = await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .getSingle();
    expect(row.uploaded, isFalse);
  });

  test("a deleted routine is recorded as deleted", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );

    await repo.deleteRoutine(routineId);

    expect(await repo.getRoutine(routineId), isNull);
    expect(await entryRows(routineId), isEmpty);
    final deleted = await db.managers.deletedPracticeRoutinesTable.get();
    expect(deleted.map((r) => r.routineId), [routineId]);
    // the exercise itself survives its routine
    expect(await repo.getExercise(exerciseId), isNotNull);
  });

  test("routine updates are announced to listeners", () async {
    final announced = <Set<String>>[];
    final sub = repo.updatedRoutineIds.listen(announced.add);
    addTearDown(sub.cancel);

    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    await repo.updateRoutine(routineId, name: "Evening", description: "");
    await repo.setRoutineEntries(routineId, []);
    await repo.deleteRoutine(routineId);
    await Future.delayed(Duration.zero);

    expect(announced, [
      {routineId},
      {routineId},
      {routineId},
      {routineId},
    ]);
  });

  test("a duplicated routine carries over its entries", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: [
        await entry(first, targetDuration: const Duration(minutes: 5)),
        await entry(second),
      ],
    );

    final copyId = await repo.duplicateRoutine(routineId);

    final copy = await repo.getRoutine(copyId!);
    expect(copy!.name, "Morning (copy)");
    expect(copy.description, "Every day");
    expect(copy.entries.map((e) => e.exercise.name), ["Chromatic", "Thirds"]);
    expect(copy.targetDuration, const Duration(minutes: 5));
    // the copy owns its entries, the sessions of the original stay with it
    final originalIds = (await repo.getRoutine(
      routineId,
    ))!.entries.map((e) => e.id).toSet();
    expect(
      copy.entries.map((e) => e.id).toSet().intersection(originalIds),
      isEmpty,
    );
    expect(await entryRows(routineId), hasLength(2));
  });

  test("duplicating keeps the notes and the default score", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await createRoutine("Morning");
    await db.managers.practiceRoutineEntriesTable.create(
      (o) => o(
        id: db.newId(),
        routine: routineId,
        exercise: exerciseId,
        position: 0,
        extraNotes: const Value("Slowly"),
        defaultScore: const Value("score-id"),
      ),
    );

    final copyId = await repo.duplicateRoutine(routineId);

    final entries = await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(copyId!))
        .get();
    expect(entries.single.extraNotes, "Slowly");
    expect(entries.single.defaultScore, "score-id");
  });

  test("an empty routine can be duplicated", () async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );

    final copyId = await repo.duplicateRoutine(routineId);

    expect((await repo.getRoutine(copyId!))!.entries, isEmpty);
    expect(await repo.countRoutines(), 2);
  });

  test("duplicating an unknown routine does nothing", () async {
    expect(await repo.duplicateRoutine("nope"), isNull);
    expect(await repo.countRoutines(), 0);
  });

  test("bulk editing the category moves every selected exercise", () async {
    final categoryId = await insertCategory("Warmup");
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    final scales = await createExercise("Scales");

    await repo.bulkUpdateExerciseCategory([bends, chromatic], categoryId);

    expect((await repo.getExercise(bends))!.category?.name, "Warmup");
    expect((await repo.getExercise(chromatic))!.category?.name, "Warmup");
    expect((await repo.getExercise(scales))!.category, isNull);
  });

  test("bulk editing the category can clear it", () async {
    final categoryId = await insertCategory("Warmup");
    final bends = await createExercise("Bends", category: categoryId);

    await repo.bulkUpdateExerciseCategory([bends], null);

    expect((await repo.getExercise(bends))!.category, isNull);
  });

  test("bulk editing the instrument clears an empty value", () async {
    final bends = await createExercise("Bends", instrument: "Guitar");
    final chromatic = await createExercise("Chromatic");

    await repo.bulkUpdateExerciseInstrument([bends, chromatic], "Bass");
    expect((await repo.getExercise(bends))!.instrument, "Bass");
    expect((await repo.getExercise(chromatic))!.instrument, "Bass");

    await repo.bulkUpdateExerciseInstrument([bends], "");
    expect((await repo.getExercise(bends))!.instrument, isNull);
  });

  test("bulk editing the source drops the link without a source", () async {
    final bends = await createExercise("Bends");

    await repo.bulkUpdateExerciseSource(
      [bends],
      source: "Book",
      sourceLink: "https://example.com",
    );
    expect((await repo.getExercise(bends))!.source, "Book");
    expect((await repo.getExercise(bends))!.sourceLink, "https://example.com");

    await repo.bulkUpdateExerciseSource(
      [bends],
      source: "",
      sourceLink: "https://example.com",
    );
    expect((await repo.getExercise(bends))!.source, isNull);
    expect((await repo.getExercise(bends))!.sourceLink, isNull);
  });

  test("bulk editing tags adds and removes them at once", () async {
    final keep = await insertTag("keep");
    final drop = await insertTag("drop");
    final bends = await repo.createExercise(
      name: "Bends",
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: [drop],
    );
    final chromatic = await createExercise("Chromatic");

    await repo.bulkEditExerciseTags([bends, chromatic], [keep], [drop]);

    expect((await repo.getExercise(bends))!.tags.map((t) => t.name), ["keep"]);
    expect((await repo.getExercise(chromatic))!.tags.map((t) => t.name), [
      "keep",
    ]);
  });

  test("bulk edits mark every touched exercise as not uploaded", () async {
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    await db.managers.exercisesTable
        .filter((f) => f.id.isIn([bends, chromatic]))
        .update((o) => o(uploaded: const Value(true)));

    await repo.bulkUpdateExerciseInstrument([bends, chromatic], "Bass");

    final rows = await db.managers.exercisesTable.get();
    expect(rows.every((e) => !e.uploaded), isTrue);
  });

  test("bulk edits of an empty selection do nothing", () async {
    final bends = await createExercise("Bends", instrument: "Guitar");

    await repo.bulkUpdateExerciseInstrument([], "Bass");

    expect((await repo.getExercise(bends))!.instrument, "Guitar");
  });

  test("deleting exercises records every one as deleted", () async {
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    final scales = await createExercise("Scales");

    await repo.deleteExercises({bends, chromatic});

    expect(await repo.countExercises(), 1);
    expect((await repo.getExercise(scales))!.name, "Scales");
    final deleted = await db.managers.deletedExercisesTable.get();
    expect(deleted.map((d) => d.exerciseId).toSet(), {bends, chromatic});
  });

  test("deleting exercises renumbers the routines they were in", () async {
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    final scales = await createExercise("Scales");
    final routineId = await createRoutine("Morning");
    await addEntry(routineId, bends, position: 0);
    await addEntry(routineId, chromatic, position: 1);
    await addEntry(routineId, scales, position: 2);

    await repo.deleteExercises({bends, chromatic});

    final rows = await entryRows(routineId);
    expect(rows.map((r) => (r.$2, r.$3)), [(scales, 0)]);
  });

  test("deleting exercises deletes the scores they own", () async {
    await insertScore("owned", type: ScoreType.exercise);
    await insertScore("linked");
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    await repo.setExerciseScores(bends, ["owned"]);
    await repo.setExerciseScores(chromatic, ["linked"]);

    await repo.deleteExercises({bends, chromatic});

    expect(await scoresRepo.getScore("owned"), isNull);
    expect(await scoresRepo.getScore("linked"), isNotNull);
  });

  test("routines are deleted together and recorded as deleted", () async {
    final morning = await createRoutine("Morning");
    final evening = await createRoutine("Evening");
    await createRoutine("Weekly");

    await repo.deleteRoutines({morning, evening});

    expect(await routineNames(), ["Weekly"]);
    final deleted = await db.managers.deletedPracticeRoutinesTable.get();
    expect(deleted.map((d) => d.routineId).toSet(), {morning, evening});
  });

  test("duplicating routines returns one copy per routine", () async {
    final morning = await createRoutine("Morning");
    final evening = await createRoutine("Evening");

    final copies = await repo.duplicateRoutines([morning, evening, "nope"]);

    expect(copies, hasLength(2));
    expect(await routineNames(), [
      "Evening",
      "Evening (copy)",
      "Morning",
      "Morning (copy)",
    ]);
  });

  test("added routine entries land after the existing ones", () async {
    final bends = await createExercise("Bends");
    final chromatic = await createExercise("Chromatic");
    final scales = await createExercise("Scales");
    final routineId = await createRoutine("Morning");
    await addEntry(routineId, bends, position: 0);

    await repo.addRoutineEntries(routineId, [chromatic, scales]);

    final rows = await entryRows(routineId);
    expect(rows.map((r) => (r.$2, r.$3)), [
      (bends, 0),
      (chromatic, 1),
      (scales, 2),
    ]);
  });

  test("adding routine entries marks the routine as not uploaded", () async {
    final bends = await createExercise("Bends");
    final routineId = await createRoutine("Morning");
    await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .update((o) => o(uploaded: const Value(true)));

    await repo.addRoutineEntries(routineId, [bends]);

    final row = await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .getSingle();
    expect(row.uploaded, isFalse);
  });

  test("getRoutineIds honours the search filter", () async {
    final morning = await createRoutine("Morning");
    await createRoutine("Evening");

    expect(await repo.getRoutineIds(filter: "morn"), [morning]);
    expect(await repo.getRoutineIds(), hasLength(2));
  });
}
