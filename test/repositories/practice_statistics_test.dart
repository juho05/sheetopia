/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/practice/practice_record.dart';
import 'package:sheetopia/data/repositories/practice/practice_statistics.dart';

void main() {
  var nextId = 0;

  PracticeRecord record(
    DateTime startedAt,
    Duration duration, {
    String exerciseId = "scales",
    DateTime? runningSince,
  }) => PracticeRecord(
    id: "${nextId++}",
    exerciseId: exerciseId,
    routineId: null,
    routineEntryId: null,
    startedAt: startedAt,
    duration: duration,
    runningSince: runningSince,
  );

  const fiveMinutes = Duration(minutes: 5);
  // a Wednesday
  final now = DateTime(2026, 3, 11, 12);

  group("period", () {
    test("a week starts at the first weekday", () {
      final monday = StatisticsPeriod.containing(StatisticsTimeFrame.week, now);
      expect(monday.start, DateTime(2026, 3, 9));
      expect(monday.end, DateTime(2026, 3, 16));

      final sunday = StatisticsPeriod.containing(
        StatisticsTimeFrame.week,
        now,
        firstWeekday: DateTime.sunday,
      );
      expect(sunday.start, DateTime(2026, 3, 8));
      expect(sunday.end, DateTime(2026, 3, 15));
    });

    test("three months end with the month of the day", () {
      final period = StatisticsPeriod.containing(
        StatisticsTimeFrame.threeMonths,
        DateTime(2026, 1, 20),
      );
      expect(period.start, DateTime(2025, 11));
      expect(period.end, DateTime(2026, 2));
    });

    test("shifting moves by whole periods", () {
      final month = StatisticsPeriod.containing(StatisticsTimeFrame.month, now);
      expect(month.shifted(-3).start, DateTime(2025, 12));
      expect(month.shifted(-3).end, DateTime(2026, 1));

      final threeMonths = StatisticsPeriod.containing(
        StatisticsTimeFrame.threeMonths,
        now,
      );
      expect(threeMonths.shifted(-1).start, DateTime(2025, 10));
      expect(threeMonths.shifted(-1).end, DateTime(2026, 1));

      final year = StatisticsPeriod.containing(StatisticsTimeFrame.year, now);
      expect(year.shifted(1).start, DateTime(2027));
    });

    test("elapsed days stop at today", () {
      final week = StatisticsPeriod.containing(StatisticsTimeFrame.week, now);
      expect(week.elapsedDays(now), 3);
      expect(week.shifted(-1).elapsedDays(now), 7);
    });
  });

  group("buckets", () {
    test("days of a week", () {
      final period = StatisticsPeriod.containing(StatisticsTimeFrame.week, now);
      final buckets = PracticeStatistics.buckets(
        [
          record(DateTime(2026, 3, 9, 8), fiveMinutes),
          record(DateTime(2026, 3, 9, 23, 50), fiveMinutes),
          record(DateTime(2026, 3, 11, 0), fiveMinutes),
          record(DateTime(2026, 3, 16, 0), fiveMinutes),
        ],
        period,
        StatisticsResolution.day,
        now: now,
      );

      expect(buckets, hasLength(7));
      expect(buckets.map((b) => b.duration.inMinutes), [10, 0, 5, 0, 0, 0, 0]);
      expect(buckets.first.start, DateTime(2026, 3, 9));
      expect(buckets.last.end, DateTime(2026, 3, 16));
    });

    test("weeks are cut off at the edges of a month", () {
      final period = StatisticsPeriod.containing(
        StatisticsTimeFrame.month,
        DateTime(2026, 4, 10),
      );
      final buckets = PracticeStatistics.buckets(
        [
          record(DateTime(2026, 4, 5, 10), fiveMinutes),
          record(DateTime(2026, 4, 6, 10), fiveMinutes),
          record(DateTime(2026, 4, 30, 10), fiveMinutes),
        ],
        period,
        StatisticsResolution.week,
        now: DateTime(2026, 5, 20),
      );

      expect(buckets.map((b) => b.start), [
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 6),
        DateTime(2026, 4, 13),
        DateTime(2026, 4, 20),
        DateTime(2026, 4, 27),
      ]);
      expect(buckets.last.end, DateTime(2026, 5, 1));
      expect(buckets.map((b) => b.duration.inMinutes), [5, 5, 0, 0, 5]);
    });

    test("months of a year", () {
      final period = StatisticsPeriod.containing(StatisticsTimeFrame.year, now);
      final buckets = PracticeStatistics.buckets(
        [
          record(DateTime(2026, 1, 31, 10), fiveMinutes),
          record(DateTime(2026, 3, 1, 10), fiveMinutes),
        ],
        period,
        StatisticsResolution.month,
        now: now,
      );

      expect(buckets, hasLength(12));
      expect(buckets[0].duration, fiveMinutes);
      expect(buckets[1].duration, Duration.zero);
      expect(buckets[2].duration, fiveMinutes);
    });

    test("a running record counts up to now", () {
      final period = StatisticsPeriod.containing(StatisticsTimeFrame.week, now);
      final buckets = PracticeStatistics.buckets(
        [
          record(
            DateTime(2026, 3, 11, 11, 50),
            fiveMinutes,
            runningSince: DateTime(2026, 3, 11, 11, 58),
          ),
        ],
        period,
        StatisticsResolution.day,
        now: now,
      );

      expect(buckets[2].duration, const Duration(minutes: 7));
    });
  });

  test("weekday totals start at the first weekday", () {
    final records = [
      record(DateTime(2026, 3, 8, 10), fiveMinutes),
      record(DateTime(2026, 3, 11, 10), fiveMinutes),
      record(DateTime(2026, 3, 4, 10), fiveMinutes),
    ];

    expect(
      PracticeStatistics.byWeekday(records, now: now).map((d) => d.inMinutes),
      [0, 0, 10, 0, 0, 0, 5],
    );
    expect(
      PracticeStatistics.byWeekday(
        records,
        now: now,
        firstWeekday: DateTime.sunday,
      ).map((d) => d.inMinutes),
      [5, 0, 0, 10, 0, 0, 0],
    );
  });

  test("a record is spread over the hours it covers", () {
    final hours = PracticeStatistics.byHour([
      record(DateTime(2026, 3, 10, 9, 50), const Duration(minutes: 80)),
    ], now: now);

    expect(hours[9], const Duration(minutes: 10));
    expect(hours[10], const Duration(minutes: 60));
    expect(hours[11], const Duration(minutes: 10));
    expect(hours.fold(Duration.zero, (a, b) => a + b).inMinutes, 80);
  });

  test("exercises are ordered by practiced time", () {
    final totals = PracticeStatistics.byExercise([
      record(DateTime(2026, 3, 10, 9), fiveMinutes),
      record(DateTime(2026, 3, 10, 10), fiveMinutes, exerciseId: "arpeggios"),
      record(DateTime(2026, 3, 11, 10), fiveMinutes, exerciseId: "arpeggios"),
    ], now: now);

    expect(totals, [
      (exerciseId: "arpeggios", duration: const Duration(minutes: 10)),
      (exerciseId: "scales", duration: fiveMinutes),
    ]);
  });

  group("streaks", () {
    test("nothing practiced has no streak", () {
      expect(PracticeStatistics.streaks([], now: now), (
        current: 0,
        longest: 0,
      ));
    });

    test("the current streak ends today", () {
      final streaks = PracticeStatistics.streaks([
        DateTime(2026, 3, 1, 10),
        DateTime(2026, 3, 2, 10),
        DateTime(2026, 3, 3, 10),
        DateTime(2026, 3, 4, 10),
        DateTime(2026, 3, 10, 10),
        DateTime(2026, 3, 10, 18),
        DateTime(2026, 3, 11, 10),
      ], now: now);

      expect(streaks, (current: 2, longest: 4));
    });

    test("the current streak survives until the end of the next day", () {
      final practicedAt = [DateTime(2026, 3, 9, 10), DateTime(2026, 3, 10, 10)];

      expect(PracticeStatistics.streaks(practicedAt, now: now).current, 2);
      expect(
        PracticeStatistics.streaks(
          practicedAt,
          now: DateTime(2026, 3, 12, 0, 1),
        ).current,
        0,
      );
    });
  });
}
