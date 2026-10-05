/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/data/repositories/practice/practice_record.dart';

enum StatisticsResolution { day, week, month }

enum StatisticsTimeFrame {
  week([StatisticsResolution.day]),
  month([StatisticsResolution.day, StatisticsResolution.week]),
  threeMonths([
    StatisticsResolution.week,
    StatisticsResolution.day,
    StatisticsResolution.month,
  ]),
  year([StatisticsResolution.month, StatisticsResolution.week]);

  /// The first entry is the default.
  final List<StatisticsResolution> resolutions;

  const StatisticsTimeFrame(this.resolutions);
}

class StatisticsPeriod {
  final StatisticsTimeFrame frame;
  final DateTime start;

  /// Exclusive.
  final DateTime end;

  const StatisticsPeriod._(this.frame, this.start, this.end);

  /// [firstWeekday] is a [DateTime.weekday] value.
  factory StatisticsPeriod.containing(
    StatisticsTimeFrame frame,
    DateTime time, {
    int firstWeekday = DateTime.monday,
  }) {
    final day = PracticeProgress.startOfDay(time);
    switch (frame) {
      case StatisticsTimeFrame.week:
        final start = PracticeStatistics.startOfWeek(day, firstWeekday);
        return StatisticsPeriod._(
          frame,
          start,
          DateTime(start.year, start.month, start.day + 7),
        );
      case StatisticsTimeFrame.month:
        return StatisticsPeriod._(
          frame,
          DateTime(day.year, day.month),
          DateTime(day.year, day.month + 1),
        );
      case StatisticsTimeFrame.threeMonths:
        return StatisticsPeriod._(
          frame,
          DateTime(day.year, day.month - 2),
          DateTime(day.year, day.month + 1),
        );
      case StatisticsTimeFrame.year:
        return StatisticsPeriod._(
          frame,
          DateTime(day.year),
          DateTime(day.year + 1),
        );
    }
  }

  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);

  StatisticsPeriod shifted(int periods) => switch (frame) {
    StatisticsTimeFrame.week => StatisticsPeriod._(
      frame,
      DateTime(start.year, start.month, start.day + 7 * periods),
      DateTime(end.year, end.month, end.day + 7 * periods),
    ),
    StatisticsTimeFrame.month => StatisticsPeriod._(
      frame,
      DateTime(start.year, start.month + periods),
      DateTime(end.year, end.month + periods),
    ),
    StatisticsTimeFrame.threeMonths => StatisticsPeriod._(
      frame,
      DateTime(start.year, start.month + 3 * periods),
      DateTime(end.year, end.month + 3 * periods),
    ),
    StatisticsTimeFrame.year => StatisticsPeriod._(
      frame,
      DateTime(start.year + periods),
      DateTime(end.year + periods),
    ),
  };

  /// Days of the period that are not in the future, at least 1.
  int elapsedDays(DateTime now) {
    final today = PracticeProgress.startOfDay(now);
    final last = today.isBefore(lastDay) ? today : lastDay;
    final days =
        PracticeStatistics.dayNumber(last) -
        PracticeStatistics.dayNumber(start) +
        1;
    return days < 1 ? 1 : days;
  }
}

class StatisticsBucket {
  final DateTime start;

  /// Exclusive.
  final DateTime end;
  final Duration duration;

  const StatisticsBucket({
    required this.start,
    required this.end,
    required this.duration,
  });

  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);
}

typedef ExerciseTotal = ({String exerciseId, Duration duration});

class PracticeStatistics {
  const PracticeStatistics._();

  /// Counts calendar days, unaffected by daylight saving time.
  static int dayNumber(DateTime time) {
    final local = time.toLocal();
    return DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  static DateTime startOfWeek(DateTime time, int firstWeekday) {
    final day = PracticeProgress.startOfDay(time);
    return DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - firstWeekday) % 7,
    );
  }

  static DateTime _nextBoundary(
    DateTime start,
    StatisticsResolution resolution,
    int firstWeekday,
  ) => switch (resolution) {
    StatisticsResolution.day => DateTime(
      start.year,
      start.month,
      start.day + 1,
    ),
    StatisticsResolution.week => () {
      final week = startOfWeek(start, firstWeekday);
      return DateTime(week.year, week.month, week.day + 7);
    }(),
    StatisticsResolution.month => DateTime(start.year, start.month + 1),
  };

  /// Weeks reaching over the edge of [period] are cut off there.
  static List<StatisticsBucket> buckets(
    Iterable<PracticeRecord> records,
    StatisticsPeriod period,
    StatisticsResolution resolution, {
    required DateTime now,
    int firstWeekday = DateTime.monday,
  }) {
    final starts = <DateTime>[];
    for (
      var cursor = period.start;
      cursor.isBefore(period.end);
      cursor = _nextBoundary(cursor, resolution, firstWeekday)
    ) {
      starts.add(cursor);
    }
    final totals = List.filled(starts.length, Duration.zero);
    for (final record in records) {
      if (!period.contains(record.startedAt)) continue;
      var low = 0;
      var high = starts.length - 1;
      while (low < high) {
        final mid = (low + high + 1) ~/ 2;
        if (starts[mid].isAfter(record.startedAt)) {
          high = mid - 1;
        } else {
          low = mid;
        }
      }
      totals[low] += record.elapsedAt(now);
    }
    return [
      for (final (i, start) in starts.indexed)
        StatisticsBucket(
          start: start,
          end: i + 1 < starts.length ? starts[i + 1] : period.end,
          duration: totals[i],
        ),
    ];
  }

  static Duration total(
    Iterable<PracticeRecord> records, {
    required DateTime now,
  }) => records.fold(Duration.zero, (sum, r) => sum + r.elapsedAt(now));

  static int daysPracticed(Iterable<PracticeRecord> records) =>
      {for (final r in records) dayNumber(r.startedAt)}.length;

  /// Seven totals, starting at [firstWeekday].
  static List<Duration> byWeekday(
    Iterable<PracticeRecord> records, {
    required DateTime now,
    int firstWeekday = DateTime.monday,
  }) {
    final totals = List.filled(7, Duration.zero);
    for (final record in records) {
      totals[(record.startedAt.weekday - firstWeekday) % 7] += record.elapsedAt(
        now,
      );
    }
    return totals;
  }

  /// 24 totals. A record is spread over the hours following its start.
  static List<Duration> byHour(
    Iterable<PracticeRecord> records, {
    required DateTime now,
  }) {
    final totals = List.filled(24, Duration.zero);
    for (final record in records) {
      var cursor = record.startedAt;
      var remaining = record.elapsedAt(now);
      while (remaining > Duration.zero) {
        final nextHour = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          cursor.hour + 1,
        );
        var chunk = nextHour.difference(cursor);
        // a daylight saving jump can leave no time until the next hour
        if (chunk <= Duration.zero || chunk > remaining) chunk = remaining;
        totals[cursor.hour] += chunk;
        remaining -= chunk;
        cursor = cursor.add(chunk);
      }
    }
    return totals;
  }

  /// Longest practiced first.
  static List<ExerciseTotal> byExercise(
    Iterable<PracticeRecord> records, {
    required DateTime now,
  }) {
    final totals = <String, Duration>{};
    for (final record in records) {
      totals[record.exerciseId] =
          (totals[record.exerciseId] ?? Duration.zero) + record.elapsedAt(now);
    }
    final result = [
      for (final MapEntry(:key, :value) in totals.entries)
        if (value > Duration.zero) (exerciseId: key, duration: value),
    ];
    result.sort((a, b) {
      final byDuration = b.duration.compareTo(a.duration);
      return byDuration != 0
          ? byDuration
          : a.exerciseId.compareTo(b.exerciseId);
    });
    return result;
  }

  /// The current streak still counts when today has not been practiced yet.
  static ({int current, int longest}) streaks(
    Iterable<DateTime> practicedAt, {
    required DateTime now,
  }) {
    final days = {for (final time in practicedAt) dayNumber(time)}.toList()
      ..sort();
    if (days.isEmpty) return (current: 0, longest: 0);
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      run = days[i] == days[i - 1] + 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }
    final today = dayNumber(now);
    final current = days.last >= today - 1 && days.last <= today ? run : 0;
    return (current: current, longest: longest);
  }
}
