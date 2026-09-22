/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/practice_record.dart';

class PracticeProgress {
  /// Records of an exercise practiced outside a routine belong together while
  /// the gap between them is shorter than this.
  static const Duration adHocWindow = Duration(minutes: 30);

  /// Records of a routine belong together when they are on the same day or the
  /// gap is shorter than max(target duration * 2, minRoutineWindow).
  static const Duration minRoutineWindow = Duration(hours: 3);

  /// The current block, oldest first.
  final List<PracticeRecord> records;

  const PracticeProgress(this.records);

  static const PracticeProgress empty = PracticeProgress([]);

  bool get isEmpty => records.isEmpty;

  PracticeRecord? get running => records.where((r) => r.running).lastOrNull;

  Duration total({DateTime? now}) => records.fold(
    Duration.zero,
    (sum, r) => sum + (now == null ? r.duration : r.elapsedAt(now)),
  );

  Duration durationFor({
    required String exerciseId,
    String? routineEntryId,
    DateTime? now,
  }) {
    var total = Duration.zero;
    for (final record in records) {
      if (!record.matches(
        exerciseId: exerciseId,
        routineEntryId: routineEntryId,
      )) {
        continue;
      }
      total += now == null ? record.duration : record.elapsedAt(now);
    }
    return total;
  }

  Map<String, Duration> byRoutineEntry({DateTime? now}) {
    final durations = <String, Duration>{};
    for (final record in records) {
      final routineEntryId = record.routineEntryId;
      if (routineEntryId == null) continue;
      durations[routineEntryId] =
          (durations[routineEntryId] ?? Duration.zero) +
          (now == null ? record.duration : record.elapsedAt(now));
    }
    return durations;
  }

  static Duration routineWindow(Duration target) =>
      target * 2 > minRoutineWindow ? target * 2 : minRoutineWindow;

  static DateTime startOfDay(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool sameDay(DateTime a, DateTime b) => startOfDay(a) == startOfDay(b);

  /// Splits [records] (oldest first, already limited to one routine or one ad
  /// hoc exercise and to startedAt >= resetAt) into blocks. Two records link
  /// when the gap between them is under [window], or when [sameDayLinks] and
  /// the block started on the same local day. Returns the last block when it
  /// is still current: a record runs, it started today with [sameDayLinks], or
  /// its last record ended less than [window] ago. Otherwise an empty progress.
  static PracticeProgress current(
    List<PracticeRecord> records, {
    required Duration window,
    required bool sameDayLinks,
    required DateTime now,
  }) {
    if (records.isEmpty) return empty;

    var blockStart = 0;
    var blockEnd = records.first.endedAt(now);
    for (var i = 1; i < records.length; i++) {
      final record = records[i];
      final linked =
          record.startedAt.difference(blockEnd) < window ||
          (sameDayLinks &&
              sameDay(records[blockStart].startedAt, record.startedAt));
      if (!linked) blockStart = i;
      final end = record.endedAt(now);
      if (!linked || end.isAfter(blockEnd)) blockEnd = end;
    }

    final block = records.sublist(blockStart);
    final current =
        block.any((r) => r.running) ||
        (sameDayLinks && sameDay(block.first.startedAt, now)) ||
        now.difference(blockEnd) < window;
    return current ? PracticeProgress(block) : empty;
  }
}
