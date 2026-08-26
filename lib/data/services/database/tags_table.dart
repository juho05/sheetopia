/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/database/exercises_table.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

enum TagType {
  @JsonValue("score")
  score,
  @JsonValue("exercise")
  exercise,
}

class TagsTable extends Table {
  late final id = text()();
  late final name = text()();
  late final color = integer()();
  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();
  late final type = textEnum<TagType>().withDefault(
    Constant(TagType.score.name),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "tags";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class ScoreTagsTable extends Table {
  late final score = text().references(
    ScoresTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final tag = text().references(
    TagsTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  @override
  String? get tableName => "score_tags";

  @override
  Set<Column<Object>>? get primaryKey => {score, tag};
}

class ExerciseTagsTable extends Table {
  late final exercise = text().references(
    ExercisesTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final tag = text().references(
    TagsTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  @override
  String? get tableName => "exercise_tags";

  @override
  Set<Column<Object>>? get primaryKey => {exercise, tag};
}
