/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class SetlistsTable extends Table {
  late final id = text()();
  late final name = text()();
  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();
  // null means the write happened at updatedAt
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "setlists";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

// Score has no foreign key because a synced setlist may reference a score
// this device has not downloaded or has deleted locally.
class SetlistEntriesTable extends Table {
  late final setlist = text().references(
    SetlistsTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final score = text()();
  late final position = integer()();

  @override
  String? get tableName => "setlist_entries";

  @override
  Set<Column<Object>>? get primaryKey => {setlist, position};
}

class DeletedSetlistsTable extends Table {
  late final setlistId = text()();
  late final deletedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  @override
  String? get tableName => "deleted_setlists";

  @override
  Set<Column<Object>>? get primaryKey => {setlistId};
}
