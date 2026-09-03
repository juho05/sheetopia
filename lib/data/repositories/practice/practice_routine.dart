/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';

class PracticeRoutineEntry {
  final String id;
  final Exercise exercise;
  final Duration? targetDuration;
  final String? defaultScoreId;

  const PracticeRoutineEntry({
    required this.id,
    required this.exercise,
    this.targetDuration,
    this.defaultScoreId,
  });

  PracticeRoutineEntry withTargetDuration(Duration? targetDuration) =>
      PracticeRoutineEntry(
        id: id,
        exercise: exercise,
        targetDuration: targetDuration,
        defaultScoreId: defaultScoreId,
      );

  PracticeRoutineEntry withDefaultScore(Score? score) => PracticeRoutineEntry(
    id: id,
    exercise: exercise,
    targetDuration: targetDuration,
    defaultScoreId: score?.id,
  );
}

class PracticeRoutine {
  final String id;
  final String name;
  final String? description;
  final int exerciseCount;
  final Duration targetDuration;
  final DateTime updatedAt;
  final List<PracticeRoutineEntry> entries;

  const PracticeRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseCount,
    required this.targetDuration,
    required this.updatedAt,
    this.entries = const [],
  });
}
