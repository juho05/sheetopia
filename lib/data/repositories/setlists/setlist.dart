/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/score.dart';

class SetlistEntry {
  final String scoreId;
  final Score? score;

  const SetlistEntry({required this.scoreId, required this.score});

  bool get playable => score?.file != null;
}

class Setlist {
  final String id;
  final String name;
  final DateTime updatedAt;
  final int entryCount;
  final List<SetlistEntry> entries;

  const Setlist({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.entryCount,
    this.entries = const [],
  });
}
