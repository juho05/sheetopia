/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:sheetopia/data/services/database/log_level_converter.dart';

class LogMessageTable extends Table {
  late final id = integer().autoIncrement()();
  late final sessionStartTime = dateTime()();
  late final time = dateTime()();
  late final level = text().map(const LogLevelConverter())();
  late final tag = text()();
  late final message = text()();
  late final stackTrace = text()();
  late final exception = text().nullable()();

  @override
  String? get tableName => "log_message";
}
