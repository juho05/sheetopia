/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class PracticeRoutine {
  final String id;
  final String name;
  final String? description;
  final int exerciseCount;
  final Duration targetDuration;
  final DateTime updatedAt;

  const PracticeRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseCount,
    required this.targetDuration,
    required this.updatedAt,
  });
}
