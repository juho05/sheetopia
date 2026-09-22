/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class PracticeRecord {
  final String id;
  final String exerciseId;
  final String? routineId;
  final String? routineEntryId;
  final DateTime startedAt;
  final Duration duration;

  /// Non-null while the stopwatch runs, set to the last checkpoint.
  final DateTime? runningSince;

  const PracticeRecord({
    required this.id,
    required this.exerciseId,
    required this.routineId,
    required this.routineEntryId,
    required this.startedAt,
    required this.duration,
    required this.runningSince,
  });

  bool get running => runningSince != null;

  Duration elapsedAt(DateTime now) {
    final runningSince = this.runningSince;
    if (runningSince == null || now.isBefore(runningSince)) return duration;
    return duration + now.difference(runningSince);
  }

  DateTime endedAt(DateTime now) => startedAt.add(elapsedAt(now));

  bool matches({required String exerciseId, String? routineEntryId}) =>
      routineEntryId != null
      ? this.routineEntryId == routineEntryId
      : this.routineEntryId == null && this.exerciseId == exerciseId;
}
