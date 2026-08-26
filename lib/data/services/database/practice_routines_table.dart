/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/duration_converter.dart';
import 'package:sheetopia/data/services/database/exercises_table.dart';

class PracticeRoutinesTable extends Table {
  late final id = text()();
  late final name = text()();
  late final description = text().nullable()();

  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "practice_routines";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@TableIndex(name: "practice_routine_entries_routine_index", columns: {#routine})
@TableIndex(
  name: "practice_routine_entries_exercise_index",
  columns: {#exercise},
)
class PracticeRoutineEntriesTable extends Table {
  late final id = text()();

  late final routine = text().references(
    PracticeRoutinesTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  late final exercise = text().references(
    ExercisesTable,
    #id,
    onUpdate: KeyAction.cascade,
    // routine must update updatedAt when entry is removed
    onDelete: KeyAction.restrict,
  )();

  late final position = integer()();
  late final extraNotes = text().nullable()();
  late final targetDuration = integer()
      .map(const DurationConverter())
      .nullable()();

  // the default alternative to pick
  late final defaultScore = text().nullable()();

  @override
  String? get tableName => "practice_routine_entries";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
