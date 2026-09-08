/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class PracticeSessionEntry {
  final String id;
  final String sessionId;
  final String exerciseId;
  final String? routineEntryId;
  final DateTime startedAt;
  final Duration duration;

  /// Non-null while the stopwatch runs, set to the last checkpoint.
  final DateTime? runningSince;

  const PracticeSessionEntry({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
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

  bool matches({required String exerciseId, String? routineEntryId}) =>
      routineEntryId != null
      ? this.routineEntryId == routineEntryId
      : this.routineEntryId == null && this.exerciseId == exerciseId;
}

class PracticeSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? routineId;
  final List<PracticeSessionEntry> entries;

  const PracticeSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.routineId,
    this.entries = const [],
  });

  DateTime get lastActivity {
    var last = endedAt ?? startedAt;
    for (final entry in entries) {
      final runningSince = entry.runningSince;
      if (runningSince != null && runningSince.isAfter(last)) {
        last = runningSince;
      }
    }
    return last;
  }

  PracticeSessionEntry? get runningEntry =>
      entries.where((e) => e.running).firstOrNull;

  /// Time practiced for one exercise, summed over the entries a midnight split
  /// may have created.
  Duration durationFor({
    required String exerciseId,
    String? routineEntryId,
    DateTime? now,
  }) {
    var total = Duration.zero;
    for (final entry in entries) {
      if (!entry.matches(
        exerciseId: exerciseId,
        routineEntryId: routineEntryId,
      )) {
        continue;
      }
      total += now == null ? entry.duration : entry.elapsedAt(now);
    }
    return total;
  }

  /// Time practiced per routine entry, a stopwatch that is still running
  /// counts up to [now].
  Map<String, Duration> durationsByRoutineEntry({DateTime? now}) {
    final durations = <String, Duration>{};
    for (final entry in entries) {
      final routineEntryId = entry.routineEntryId;
      if (routineEntryId == null) continue;
      durations[routineEntryId] =
          (durations[routineEntryId] ?? Duration.zero) +
          (now == null ? entry.duration : entry.elapsedAt(now));
    }
    return durations;
  }
}
