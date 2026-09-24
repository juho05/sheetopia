/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/duration_converter.dart';

@TableIndex(name: "practice_records_started_at_index", columns: {#startedAt})
@TableIndex.sql(
  "CREATE INDEX practice_records_started_at_julianday_index "
  "ON practice_records (julianday(started_at))",
)
@TableIndex(name: "practice_records_exercise_index", columns: {#exercise})
@TableIndex(name: "practice_records_routine_index", columns: {#routine})
class PracticeRecordsTable extends Table {
  late final id = text()();

  // no foreign keys, a practice record must survive what it points at
  late final exercise = text()();
  late final routine = text().nullable()();
  late final routineEntry = text().nullable()();

  // a record only holds time practiced on the local day of startedAt, a
  // stopwatch running over midnight is split into a second record
  late final startedAt = dateTime()();

  // only the time folded in by the last checkpoint, see runningSince
  late final duration = integer()
      .map(const DurationConverter())
      .withDefault(const Constant(0))();

  // total elapsed is duration + (now - runningSince). Local only, never synced.
  // Null if the stopwatch is not running.
  late final runningSince = dateTime().nullable()();

  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "practice_records";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
