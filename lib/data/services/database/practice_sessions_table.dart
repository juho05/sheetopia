/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/duration_converter.dart';

@TableIndex(name: "practice_sessions_started_at_index", columns: {#startedAt})
@TableIndex(name: "practice_sessions_routine_index", columns: {#routine})
class PracticeSessionsTable extends Table {
  late final id = text()();
  late final startedAt = dateTime()();
  late final endedAt = dateTime().nullable()();

  // no foreign key, the log has to outlive the routine it was practiced from
  late final routine = text().nullable()();

  late final description = text().nullable()();

  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "practice_sessions";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@TableIndex(
  name: "practice_session_entries_exercise_index",
  columns: {#exercise},
)
@TableIndex(
  name: "practice_session_entries_routine_entry_index",
  columns: {#routineEntry},
)
class PracticeSessionEntriesTable extends Table {
  late final id = text()();

  late final session = text().references(
    PracticeSessionsTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  // no foreign keys, a practice record must survive what it points at
  late final exercise = text()();
  late final routineEntry = text().nullable()();

  // only the time folded in by the last checkpoint, see runningSince
  late final duration = integer()
      .map(const DurationConverter())
      .withDefault(const Constant(0))();

  // total elapsed is duration + (now - runningSince). RunningSince is periodically
  // reset to now after duration is updated. Null if the stopwatch is not running.
  late final runningSince = dateTime().nullable()();

  @override
  String? get tableName => "practice_session_entries";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
