/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/exercise_categories_table.dart';

@TableIndex(name: "exercises_category_index", columns: {#category})
class ExercisesTable extends Table {
  late final id = text()();
  late final name = text()();

  late final category = text().nullable().references(
    ExerciseCategoriesTable,
    #id,
    onUpdate: KeyAction.cascade,
    // the exercise must update updatedAt when its category is removed
    onDelete: KeyAction.restrict,
  )();

  late final description = text().nullable()();
  late final source = text().nullable()();
  late final sourceLink = text().nullable()();
  late final instrument = text().nullable()();
  late final targetBpm = integer().nullable()();

  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "exercises";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@TableIndex(name: "exercise_scores_score_index", columns: {#score})
class ExerciseScoresTable extends Table {
  late final exercise = text().references(
    ExercisesTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  // deliberately not a foreign key to scores to handle missing scores
  late final score = text()();
  late final position = integer()();

  @override
  String? get tableName => "exercise_scores";

  @override
  Set<Column<Object>>? get primaryKey => {exercise, position};
}
