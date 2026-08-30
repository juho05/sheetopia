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
}
