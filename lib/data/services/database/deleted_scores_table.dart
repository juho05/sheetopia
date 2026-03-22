/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

class DeletedScoresTable extends Table {
  late final scoreId = text()();
  late final deletedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  @override
  String? get tableName => "deleted_scores";

  @override
  Set<Column<Object>>? get primaryKey => {scoreId};
}
