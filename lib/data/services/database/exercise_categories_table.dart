/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class ExerciseCategoriesTable extends Table {
  late final id = text()();
  late final name = text()();
  late final position = integer()();

  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "exercise_categories";

  @override
  Set<Column<Object>>? get primaryKey => {id};
}
