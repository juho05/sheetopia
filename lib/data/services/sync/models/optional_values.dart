/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

Value<String?> optionalStringValue(String? str) {
  if (str == null) return const Value.absent();
  if (str == "") return const Value(null);
  return Value(str);
}

Value<DateTime?> optionalDateTimeValue(String? str) {
  if (str == null) return const Value.absent();
  if (str == "") return const Value(null);
  return Value(DateTime.parse(str).toUtc());
}

Value<int?> optionalIntValue(int? value) {
  if (value == null) return const Value.absent();
  if (value == 0) return const Value(null);
  return Value(value);
}

Value<Duration?> optionalDurationValue(int? milliseconds) {
  if (milliseconds == null) return const Value.absent();
  if (milliseconds == 0) return const Value(null);
  return Value(Duration(milliseconds: milliseconds));
}
