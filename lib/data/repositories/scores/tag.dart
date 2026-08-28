/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:ui';

import 'package:sheetopia/data/services/database/tags_table.dart';

class Tag {
  final String id;
  final String name;
  final Color color;
  final TagType type;
  final DateTime updatedAt;

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.type,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Tag) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
