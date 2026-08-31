/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class PracticeRepository {
  final Database _db;
  final ScoresRepository _scoresRepo;

  final BehaviorSubject<Set<String>> _updatedExerciseIds = BehaviorSubject();

  Stream<Set<String>> get updatedExerciseIds => _updatedExerciseIds.stream;

  final BehaviorSubject<Set<String>> _updatedCategoryIds = BehaviorSubject();

  Stream<Set<String>> get updatedCategoryIds => _updatedCategoryIds.stream;

  final BehaviorSubject<Set<String>> _updatedRoutineIds = BehaviorSubject();

  Stream<Set<String>> get updatedRoutineIds => _updatedRoutineIds.stream;

  PracticeRepository({required this._db, required this._scoresRepo}) {
    _scoresRepo.deletedScoreIds.listen(removeDeletedScoreEntries);
  }

  static final _whitespaceRegex = RegExp(r'\s+');

  Iterable<String> _searchWords(String filter) {
    filter = filter.trim();
    if (filter.isEmpty) return const [];
    return filter.split(_whitespaceRegex);
  }

  Expression<bool> _matchHaving(
    FilterMatchType type,
    Expression<int> matchingCount,
    Expression<int> totalCount,
    int selectedLen,
  ) {
    switch (type) {
      case FilterMatchType.any:
        return matchingCount.isBiggerThanValue(0);
      case FilterMatchType.all:
        return matchingCount.equals(selectedLen);
      case FilterMatchType.exact:
        return matchingCount.equals(selectedLen) &
            totalCount.equals(selectedLen);
    }
  }

  List<Join> _filterJoins({
    required Iterable<String> tagIds,
    required FilterMatchType tagMatch,
  }) {
    final tagsSubQ = _db.selectOnly(_db.exerciseTagsTable).join([]);
    tagsSubQ.addColumns([_db.exerciseTagsTable.exercise]);
    tagsSubQ.groupBy(
      [_db.exerciseTagsTable.exercise],
      having: _matchHaving(
        tagMatch,
        _db.exerciseTagsTable.tag.count(
          distinct: true,
          filter: _db.exerciseTagsTable.tag.isIn(tagIds),
        ),
        _db.exerciseTagsTable.tag.count(distinct: true),
        tagIds.length,
      ),
    );
    final assignedToTags = Subquery(tagsSubQ, 'assigned_to_tags');

    return [
      leftOuterJoin(
        _db.exerciseCategoriesTable,
        _db.exerciseCategoriesTable.id.equalsExp(_db.exercisesTable.category),
      ),
      if (tagIds.isNotEmpty)
        innerJoin(
          assignedToTags,
          assignedToTags
              .ref(_db.exerciseTagsTable.exercise)
              .equalsExp(_db.exercisesTable.id),
          useColumns: false,
        ),
    ];
  }

  void _applyExerciseFilters(
    JoinedSelectStatement q,
    Iterable<String> searchWords,
    String? categoryId,
    String instrument,
  ) {
    for (final word in searchWords) {
      q.where(_db.exercisesTable.name.contains(word));
    }
    if (categoryId != null) {
      q.where(_db.exercisesTable.category.equals(categoryId));
    }
    if (instrument.isNotEmpty) {
      q.where(_db.exercisesTable.instrument.equals(instrument));
    }
  }

  List<OrderingTerm> get _exerciseOrdering => [
    OrderingTerm.asc(
      _db.exerciseCategoriesTable.position,
      nulls: NullsOrder.last,
    ),
    OrderingTerm.asc(_db.exerciseCategoriesTable.id),
    OrderingTerm.asc(_db.exercisesTable.name.lower()),
    OrderingTerm.asc(_db.exercisesTable.id),
  ];

  Future<int> countExercises({
    String filter = "",
    String? categoryId,
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final countExpr = _db.exercisesTable.id.count(distinct: true);
    final q = _db
        .selectOnly(_db.exercisesTable)
        .join(_filterJoins(tagIds: tagIds, tagMatch: tagMatch));
    q.addColumns([countExpr]);
    _applyExerciseFilters(q, _searchWords(filter), categoryId, instrument);
    return (await q.getSingle()).read(countExpr) ?? 0;
  }

  Future<List<String>> getExerciseIds({
    String filter = "",
    String? categoryId,
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final q = _db
        .selectOnly(_db.exercisesTable)
        .join(_filterJoins(tagIds: tagIds, tagMatch: tagMatch));
    q.addColumns([_db.exercisesTable.id]);
    _applyExerciseFilters(q, _searchWords(filter), categoryId, instrument);
    q.orderBy(_exerciseOrdering);
    final rows = await q.get();
    return rows.map((row) => row.read(_db.exercisesTable.id)!).toList();
  }

  Future<List<Exercise>> getExercises({
    required int size,
    int offset = 0,
    String filter = "",
    String? categoryId,
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final q = _db
        .select(_db.exercisesTable)
        .join(_filterJoins(tagIds: tagIds, tagMatch: tagMatch));
    _applyExerciseFilters(q, _searchWords(filter), categoryId, instrument);
    q.orderBy(_exerciseOrdering);
    q.limit(size, offset: offset);

    final rows = [
      for (final row in await q.get())
        (
          row.readTable(_db.exercisesTable),
          row.readTableOrNull(_db.exerciseCategoriesTable),
        ),
    ];
    final tags = await _getExercisesTags(rows.map((r) => r.$1.id));

    return [
      for (final (exercise, category) in rows)
        Exercise(
          id: exercise.id,
          name: exercise.name,
          category: category == null
              ? null
              : ExerciseCategory(id: category.id, name: category.name),
          instrument: exercise.instrument,
          tags: tags[exercise.id] ?? const [],
          description: exercise.description,
          source: exercise.source,
          sourceLink: exercise.sourceLink,
        ),
    ];
  }

  Future<List<ExerciseCategory>> getAllCategories() async {
    return (await _orderedCategories())
        .map((c) => ExerciseCategory(id: c.id, name: c.name))
        .toList();
  }

  Future<Map<String, int>> countExercisesPerCategory() async {
    final countExpr = _db.exercisesTable.id.count();
    final q = _db.selectOnly(_db.exercisesTable)
      ..addColumns([_db.exercisesTable.category, countExpr])
      ..where(_db.exercisesTable.category.isNotNull())
      ..groupBy([_db.exercisesTable.category]);
    return {
      for (final row in await q.get())
        row.read(_db.exercisesTable.category)!: row.read(countExpr) ?? 0,
    };
  }

  Future<ExerciseCategory> createCategory(String name) async {
    final categoryId = _db.newId();
    await _db.transaction(() async {
      final maxPosition = _db.exerciseCategoriesTable.position.max();
      final q = _db.selectOnly(_db.exerciseCategoriesTable)
        ..addColumns([maxPosition]);
      final position = ((await q.getSingle()).read(maxPosition) ?? -1) + 1;
      await _db.managers.exerciseCategoriesTable.create(
        (o) => o(
          id: categoryId,
          name: name,
          position: position,
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
    });
    _updatedCategoryIds.add({categoryId});
    return ExerciseCategory(id: categoryId, name: name);
  }

  Future<void> renameCategory(String categoryId, String name) async {
    await _db.managers.exerciseCategoriesTable
        .filter((f) => f.id(categoryId))
        .update(
          (o) => o(
            name: Value(name),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    _updatedCategoryIds.add({categoryId});
  }

  Future<void> deleteCategory(String categoryId) async {
    final exerciseIds = <String>{};
    final movedIds = <String>{};
    await _db.transaction(() async {
      final query = _db.select(_db.exercisesTable)
        ..where((t) => t.category.equals(categoryId));
      exerciseIds.addAll((await query.get()).map((e) => e.id));
      if (exerciseIds.isNotEmpty) {
        await _db.managers.exercisesTable
            .filter((f) => f.id.isIn(exerciseIds))
            .update(
              (o) => o(
                category: const Value(null),
                updatedAt: Value(DateTime.now().toUtc()),
                uploaded: const Value(false),
              ),
            );
      }
      await _db.managers.exerciseCategoriesTable
          .filter((f) => f.id(categoryId))
          .delete();
      await _db.managers.deletedExerciseCategoriesTable.create(
        (o) =>
            o(categoryId: categoryId, deletedAt: Value(DateTime.now().toUtc())),
      );
      movedIds.addAll(
        await _writeCategoryPositions(await _orderedCategories()),
      );
    });
    if (exerciseIds.isNotEmpty) _updatedExerciseIds.add(exerciseIds);
    _updatedCategoryIds.add({categoryId, ...movedIds});
  }

  Future<void> moveCategory(int from, int to) async {
    final movedIds = <String>{};
    await _db.transaction(() async {
      final categories = await _orderedCategories();
      if (from < 0 || from >= categories.length) return;
      if (to < 0 || to >= categories.length) return;
      categories.insert(to, categories.removeAt(from));
      movedIds.addAll(await _writeCategoryPositions(categories));
    });
    if (movedIds.isEmpty) return;
    _updatedCategoryIds.add(movedIds);
  }

  Future<List<ExerciseCategoriesTableData>> _orderedCategories() async {
    final query = _db.select(_db.exerciseCategoriesTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.position),
        (t) => OrderingTerm.asc(t.name.lower()),
      ]);
    return await query.get();
  }

  Future<Set<String>> _writeCategoryPositions(
    List<ExerciseCategoriesTableData> categories,
  ) async {
    final changed = <String>{};
    for (final (position, category) in categories.indexed) {
      if (category.position == position) continue;
      await _db.managers.exerciseCategoriesTable
          .filter((f) => f.id(category.id))
          .update(
            (o) => o(
              position: Value(position),
              updatedAt: Value(DateTime.now().toUtc()),
              uploaded: const Value(false),
            ),
          );
      changed.add(category.id);
    }
    return changed;
  }

  Future<Exercise?> getExercise(String exerciseId) async {
    final query = _db.select(_db.exercisesTable).join([
      leftOuterJoin(
        _db.exerciseCategoriesTable,
        _db.exerciseCategoriesTable.id.equalsExp(_db.exercisesTable.category),
      ),
    ])..where(_db.exercisesTable.id.equals(exerciseId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final exercise = row.readTable(_db.exercisesTable);
    final category = row.readTableOrNull(_db.exerciseCategoriesTable);

    return Exercise(
      id: exercise.id,
      name: exercise.name,
      category: category == null
          ? null
          : ExerciseCategory(id: category.id, name: category.name),
      instrument: exercise.instrument,
      tags: await _getExerciseTags(exercise.id),
      description: exercise.description,
      source: exercise.source,
      sourceLink: exercise.sourceLink,
    );
  }

  Future<List<Tag>> _getExerciseTags(String exerciseId) async {
    return (await _db.managers.tagsTable
            .filter(
              (f) => f.exerciseTagsTableRefs((f) => f.exercise.id(exerciseId)),
            )
            .orderBy((o) => o.name.asc())
            .get())
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            color: Color(t.color),
            type: t.type,
            updatedAt: t.updatedAt.toUtc(),
          ),
        )
        .toList();
  }

  Future<Map<String, List<Tag>>> _getExercisesTags(
    Iterable<String> exerciseIds,
  ) async {
    if (exerciseIds.isEmpty) return const {};
    final exerciseTags = <String, List<Tag>>{};

    final tags = await _db.managers.tagsTable
        .filter(
          (f) =>
              f.exerciseTagsTableRefs((f) => f.exercise.id.isIn(exerciseIds)),
        )
        .orderBy((o) => o.name.asc())
        .withReferences((prefetch) => prefetch(exerciseTagsTableRefs: true))
        .get(distinct: true);
    for (final t in tags) {
      final tag = Tag(
        id: t.$1.id,
        name: t.$1.name,
        color: Color(t.$1.color),
        type: t.$1.type,
        updatedAt: t.$1.updatedAt.toUtc(),
      );
      final refs =
          t.$2.exerciseTagsTableRefs.prefetchedData ??
          <ExerciseTagsTableData>[];
      for (final ref in refs) {
        (exerciseTags[ref.exercise] ??= []).add(tag);
      }
    }

    return exerciseTags;
  }

  Future<String> createExercise({
    required String name,
    required String description,
    required String instrument,
    required String source,
    required String sourceLink,
    required Iterable<String> tagIds,
    Iterable<String> scoreIds = const [],
    String? categoryId,
  }) async {
    final exerciseId = _db.newId();
    await _db.transaction(() async {
      await _db.managers.exercisesTable.create(
        (o) => o(
          id: exerciseId,
          name: name,
          category: Value(categoryId),
          description: description.isNotEmpty
              ? Value(description)
              : const Value(null),
          instrument: instrument.isNotEmpty
              ? Value(instrument)
              : const Value(null),
          source: source.isNotEmpty ? Value(source) : const Value(null),
          sourceLink: source.isNotEmpty && sourceLink.isNotEmpty
              ? Value(sourceLink)
              : const Value(null),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      if (tagIds.isNotEmpty) {
        await _db.managers.exerciseTagsTable.bulkCreate(
          (o) => tagIds.map((id) => o(exercise: exerciseId, tag: id)),
          onConflict: DoNothing(),
        );
      }
      if (scoreIds.isNotEmpty) {
        await _db.managers.exerciseScoresTable.bulkCreate(
          (o) => scoreIds.indexed.map(
            (e) => o(exercise: exerciseId, score: e.$2, position: e.$1),
          ),
        );
      }
    });
    _updatedExerciseIds.add({exerciseId});
    return exerciseId;
  }

  Future<void> updateExercise(
    String exerciseId, {
    required String name,
    required String description,
    required String instrument,
  }) async {
    await _db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .update(
          (o) => o(
            name: Value(name),
            description: description.isNotEmpty
                ? Value(description)
                : const Value(null),
            instrument: instrument.isNotEmpty
                ? Value(instrument)
                : const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    _updatedExerciseIds.add({exerciseId});
  }

  Future<void> updateExerciseCategory(
    String exerciseId,
    String? categoryId,
  ) async {
    await _db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .update(
          (o) => o(
            category: Value(categoryId),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    _updatedExerciseIds.add({exerciseId});
  }

  Future<void> updateExerciseSource(
    String exerciseId, {
    required String source,
    required String sourceLink,
  }) async {
    await _db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .update(
          (o) => o(
            source: source.isNotEmpty ? Value(source) : const Value(null),
            sourceLink: source.isNotEmpty && sourceLink.isNotEmpty
                ? Value(sourceLink)
                : const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    _updatedExerciseIds.add({exerciseId});
  }

  Future<void> addExerciseTags(
    String exerciseId,
    Iterable<String> tagIds,
  ) async {
    if (tagIds.isEmpty) return;
    await _db.transaction(() async {
      await _db.managers.exerciseTagsTable.bulkCreate(
        (o) => tagIds.map((id) => o(exercise: exerciseId, tag: id)),
        onConflict: DoNothing(),
      );
      await _markUpdated(exerciseId);
    });
    _updatedExerciseIds.add({exerciseId});
  }

  Future<void> removeExerciseTag(String exerciseId, String tagId) async {
    await _db.transaction(() async {
      await _db.managers.exerciseTagsTable
          .filter((f) => f.exercise.id(exerciseId) & f.tag.id(tagId))
          .delete();
      await _markUpdated(exerciseId);
    });
    _updatedExerciseIds.add({exerciseId});
  }

  Future<List<String>> getExerciseScoreIds(String exerciseId) async {
    final query =
        _db.select(_db.exerciseScoresTable).join([
            innerJoin(
              _db.scoresTable,
              _db.scoresTable.id.equalsExp(_db.exerciseScoresTable.score),
            ),
          ])
          ..where(_db.exerciseScoresTable.exercise.equals(exerciseId))
          ..orderBy([OrderingTerm.asc(_db.exerciseScoresTable.position)]);
    return [
      for (final row in await query.get())
        row.readTable(_db.exerciseScoresTable).score,
    ];
  }

  Future<List<Score>> getExerciseScores(String exerciseId) async {
    final query =
        _db.select(_db.exerciseScoresTable).join([
            innerJoin(
              _db.scoresTable,
              _db.scoresTable.id.equalsExp(_db.exerciseScoresTable.score),
            ),
          ])
          ..where(_db.exerciseScoresTable.exercise.equals(exerciseId))
          ..orderBy([OrderingTerm.asc(_db.exerciseScoresTable.position)]);
    return _scoresRepo.hydrateScores([
      for (final row in await query.get()) row.readTable(_db.scoresTable),
    ]);
  }

  Future<void> setExerciseScores(
    String exerciseId,
    List<String> scoreIds,
  ) async {
    Iterable<String?> scoreIdsToDelete = {};
    await _db.transaction(() async {
      final oldScores = await getExerciseScoreIds(exerciseId);

      await _db.managers.exerciseScoresTable
          .filter((f) => f.exercise.id(exerciseId))
          .delete();
      await _db.managers.exerciseScoresTable.bulkCreate(
        (o) => scoreIds.indexed.map(
          (e) => o(exercise: exerciseId, score: e.$2, position: e.$1),
        ),
      );

      final linkedScoreIdsQuery = _db.selectOnly(_db.exerciseScoresTable)
        ..addColumns([_db.exerciseScoresTable.score])
        ..where(_db.exerciseScoresTable.exercise.equals(exerciseId));

      scoreIdsToDelete =
          (await (_db.selectOnly(_db.scoresTable)
                    ..addColumns([_db.scoresTable.id])
                    ..where(
                      _db.scoresTable.id.isIn(oldScores) &
                          _db.scoresTable.type.equalsValue(ScoreType.exercise) &
                          _db.scoresTable.id.isNotInQuery(linkedScoreIdsQuery),
                    ))
                  .get())
              .map((rs) => rs.read(_db.scoresTable.id));

      await _markUpdated(exerciseId);
    });
    await _scoresRepo.deleteScores(scoreIdsToDelete.nonNulls.toSet());
    _updatedExerciseIds.add({exerciseId});
  }

  Future<void> removeDeletedScoreEntries(Set<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    final affected = <String>{};
    await _db.transaction(() async {
      final exercise = _db.exerciseScoresTable.exercise;
      final query = _db.selectOnly(_db.exerciseScoresTable, distinct: true)
        ..addColumns([exercise])
        ..where(_db.exerciseScoresTable.score.isIn(scoreIds));
      affected.addAll((await query.get()).map((row) => row.read(exercise)!));
      if (affected.isEmpty) return;
      await _db.managers.exerciseScoresTable
          .filter((f) => f.score.isIn(scoreIds))
          .delete();
      await _db.managers.exercisesTable
          .filter((f) => f.id.isIn(affected))
          .update(
            (o) => o(
              updatedAt: Value(DateTime.now().toUtc()),
              uploaded: const Value(false),
            ),
          );
    });
    if (affected.isEmpty) return;
    _updatedExerciseIds.add(affected);
  }

  Future<void> deleteExercise(String exerciseId) async {
    Iterable<String?> scoreIdsToDelete = {};
    final routineIds = <String>{};
    await _db.transaction(() async {
      routineIds.addAll(
        await _db.managers.practiceRoutineEntriesTable
            .filter((f) => f.exercise.id(exerciseId))
            .map((e) => e.routine)
            .get(),
      );
      if (routineIds.isNotEmpty) {
        await _db.managers.practiceRoutineEntriesTable
            .filter((f) => f.exercise.id(exerciseId))
            .delete();
        for (final routineId in routineIds) {
          await _renumberRoutineEntries(routineId);
        }
        await _db.managers.practiceRoutinesTable
            .filter((f) => f.id.isIn(routineIds))
            .update(
              (o) => o(
                updatedAt: Value(DateTime.now().toUtc()),
                uploaded: const Value(false),
              ),
            );
      }
      final q =
          (_db.selectOnly(
            _db.exerciseScoresTable,
          )..addColumns([_db.exerciseScoresTable.score])).join([
            innerJoin(
              _db.scoresTable,
              _db.scoresTable.id.equalsExp(_db.exerciseScoresTable.score),
            ),
          ]);

      scoreIdsToDelete =
          (await (q..where(
                    _db.scoresTable.type.equalsValue(ScoreType.exercise) &
                        _db.exerciseScoresTable.exercise.equals(exerciseId),
                  ))
                  .get())
              .map((s) => s.read(_db.exerciseScoresTable.score))
              .where((id) => id != null)
              .map((id) => id!);
      await _db.managers.exercisesTable
          .filter((f) => f.id(exerciseId))
          .delete();
      await _db.managers.deletedExercisesTable.create(
        (o) =>
            o(exerciseId: exerciseId, deletedAt: Value(DateTime.now().toUtc())),
      );
    });
    await _scoresRepo.deleteScores(scoreIdsToDelete.nonNulls.toSet());
    _updatedExerciseIds.add({exerciseId});
    if (routineIds.isNotEmpty) _updatedRoutineIds.add(routineIds);
  }

  Future<List<String>> getInstruments({String filter = "", int? size}) async {
    final exerciseQuery = _db.selectOnly(_db.exercisesTable, distinct: true)
      ..addColumns([_db.exercisesTable.instrument])
      ..where(_db.exercisesTable.instrument.isNotNull());
    final scoreQuery = _db.selectOnly(_db.instrumentsTable, distinct: true)
      ..addColumns([_db.instrumentsTable.instrument]);
    if (filter.isNotEmpty) {
      exerciseQuery.where(_db.exercisesTable.instrument.contains(filter));
      scoreQuery.where(_db.instrumentsTable.instrument.contains(filter));
    }
    return _merge([
      ...(await exerciseQuery.get()).map(
        (r) => r.read(_db.exercisesTable.instrument)!,
      ),
      ...(await scoreQuery.get()).map(
        (r) => r.read(_db.instrumentsTable.instrument)!,
      ),
    ], size);
  }

  Future<List<String>> getSources({String filter = "", int? size}) async {
    final exerciseQuery = _db.selectOnly(_db.exercisesTable, distinct: true)
      ..addColumns([_db.exercisesTable.source])
      ..where(_db.exercisesTable.source.isNotNull());
    final scoreQuery = _db.selectOnly(_db.scoresTable, distinct: true)
      ..addColumns([_db.scoresTable.source])
      ..where(_db.scoresTable.source.isNotNull());
    if (filter.isNotEmpty) {
      exerciseQuery.where(_db.exercisesTable.source.contains(filter));
      scoreQuery.where(_db.scoresTable.source.contains(filter));
    }
    return _merge([
      ...(await exerciseQuery.get()).map(
        (r) => r.read(_db.exercisesTable.source)!,
      ),
      ...(await scoreQuery.get()).map((r) => r.read(_db.scoresTable.source)!),
    ], size);
  }

  List<String> _merge(Iterable<String> values, int? size) {
    final merged = values.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (size == null || merged.length <= size) return merged;
    return merged.sublist(0, size);
  }

  Expression<bool> _routineInstrumentFilter(String instrument) {
    final q = _db.selectOnly(_db.practiceRoutineEntriesTable).join([
      innerJoin(
        _db.exercisesTable,
        _db.exercisesTable.id.equalsExp(
          _db.practiceRoutineEntriesTable.exercise,
        ),
        useColumns: false,
      ),
    ]);
    q.addColumns([_db.practiceRoutineEntriesTable.routine]);
    q.where(_db.exercisesTable.instrument.equals(instrument));
    return _db.practiceRoutinesTable.id.isInQuery(q);
  }

  Expression<bool> _routineTagFilter(
    Iterable<String> tagIds,
    FilterMatchType tagMatch,
  ) {
    final tag = _db.exerciseTagsTable.tag;
    final q = _db.selectOnly(_db.practiceRoutineEntriesTable).join([
      innerJoin(
        _db.exerciseTagsTable,
        _db.exerciseTagsTable.exercise.equalsExp(
          _db.practiceRoutineEntriesTable.exercise,
        ),
        useColumns: false,
      ),
    ]);
    q.addColumns([_db.practiceRoutineEntriesTable.routine]);
    q.groupBy(
      [_db.practiceRoutineEntriesTable.routine],
      having: _matchHaving(
        tagMatch,
        tag.count(distinct: true, filter: tag.isIn(tagIds)),
        tag.count(distinct: true),
        tagIds.length,
      ),
    );
    return _db.practiceRoutinesTable.id.isInQuery(q);
  }

  void _applyRoutineFilters(
    JoinedSelectStatement q,
    String filter,
    String instrument,
    Iterable<String> tagIds,
    FilterMatchType tagMatch,
  ) {
    for (final word in _searchWords(filter)) {
      q.where(_db.practiceRoutinesTable.name.contains(word));
    }
    if (instrument.isNotEmpty) {
      q.where(_routineInstrumentFilter(instrument));
    }
    if (tagIds.isNotEmpty) {
      q.where(_routineTagFilter(tagIds, tagMatch));
    }
  }

  List<OrderingTerm> get _routineOrdering => [
    OrderingTerm.asc(_db.practiceRoutinesTable.name.lower()),
    OrderingTerm.asc(_db.practiceRoutinesTable.id),
  ];

  Future<int> countRoutines({
    String filter = "",
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final countExpr = _db.practiceRoutinesTable.id.count(distinct: true);
    final q = _db.selectOnly(_db.practiceRoutinesTable);
    q.addColumns([countExpr]);
    _applyRoutineFilters(q, filter, instrument, tagIds, tagMatch);
    return (await q.getSingle()).read(countExpr) ?? 0;
  }

  Future<List<PracticeRoutine>> getRoutines({
    required int size,
    int offset = 0,
    String filter = "",
    String instrument = "",
    Iterable<String> tagIds = const [],
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final entries = _db.practiceRoutineEntriesTable;
    final countExpr = entries.id.count();
    final durationExpr = entries.targetDuration.sum();
    final q = _db.selectOnly(_db.practiceRoutinesTable).join([
      leftOuterJoin(
        entries,
        entries.routine.equalsExp(_db.practiceRoutinesTable.id),
        useColumns: false,
      ),
    ]);
    q.addColumns([
      _db.practiceRoutinesTable.id,
      _db.practiceRoutinesTable.name,
      _db.practiceRoutinesTable.description,
      _db.practiceRoutinesTable.updatedAt,
      countExpr,
      durationExpr,
    ]);
    _applyRoutineFilters(q, filter, instrument, tagIds, tagMatch);
    q.groupBy([_db.practiceRoutinesTable.id]);
    q.orderBy(_routineOrdering);
    q.limit(size, offset: offset);

    return [
      for (final row in await q.get())
        PracticeRoutine(
          id: row.read(_db.practiceRoutinesTable.id)!,
          name: row.read(_db.practiceRoutinesTable.name)!,
          description: row.read(_db.practiceRoutinesTable.description),
          exerciseCount: row.read(countExpr) ?? 0,
          targetDuration: Duration(milliseconds: row.read(durationExpr) ?? 0),
          updatedAt: row.read(_db.practiceRoutinesTable.updatedAt)!.toUtc(),
        ),
    ];
  }

  Future<void> _renumberRoutineEntries(String routineId) async {
    final query = _db.select(_db.practiceRoutineEntriesTable)
      ..where((t) => t.routine.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    final entries = await query.get();
    for (final (position, entry) in entries.indexed) {
      if (entry.position == position) continue;
      await _db.managers.practiceRoutineEntriesTable
          .filter((f) => f.id(entry.id))
          .update((o) => o(position: Value(position)));
    }
  }

  Future<void> _markUpdated(String exerciseId) async {
    await _db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .update(
          (o) => o(
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
  }
}
