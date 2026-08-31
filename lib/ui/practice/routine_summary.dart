/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/heading.dart';

String formatRoutineDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return "${minutes}min";
  return "${hours}h ${minutes}min";
}

String routineSummary(int count, Duration targetDuration) {
  final exercises = "$count ${count == 1 ? "exercise" : "exercises"}";
  if (targetDuration == Duration.zero) return exercises;
  return "$exercises • ${formatRoutineDuration(targetDuration)}";
}

class RoutineExercisesHeader extends StatelessWidget {
  final int count;
  final Duration targetDuration;

  const RoutineExercisesHeader({
    super.key,
    required this.count,
    required this.targetDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Expanded(child: Heading(text: "Exercises")),
          Text(
            routineSummary(count, targetDuration),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
