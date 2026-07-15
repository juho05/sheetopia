/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class AnnotationsTable extends Table {
  late final score = text().references(
    ScoresTable,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  late final pageIndex = integer()();
  late final data = text()();
  late final updatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();
  late final uploaded = boolean().withDefault(const Constant(false))();

  @override
  String? get tableName => "annotations";

  @override
  Set<Column<Object>>? get primaryKey => {score, pageIndex};
}
