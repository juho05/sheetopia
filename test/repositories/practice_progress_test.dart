/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/data/repositories/practice/practice_record.dart';

void main() {
  var nextId = 0;

  PracticeRecord record(
    DateTime startedAt,
    Duration duration, {
    String exerciseId = "scales",
    String? routineEntryId,
    DateTime? runningSince,
  }) => PracticeRecord(
    id: "${nextId++}",
    exerciseId: exerciseId,
    routineId: routineEntryId == null ? null : "morning",
    routineEntryId: routineEntryId,
    startedAt: startedAt,
    duration: duration,
    runningSince: runningSince,
  );

  PracticeProgress adHoc(List<PracticeRecord> records, DateTime now) =>
      PracticeProgress.current(
        records,
        window: PracticeProgress.adHocWindow,
        sameDayLinks: false,
        now: now,
      );

  PracticeProgress routine(
    List<PracticeRecord> records,
    DateTime now, {
    Duration target = const Duration(minutes: 30),
  }) => PracticeProgress.current(
    records,
    window: PracticeProgress.routineWindow(target),
    sameDayLinks: true,
    now: now,
  );

  const fiveMinutes = Duration(minutes: 5);

  test("nothing practiced is an empty progress", () {
    expect(adHoc([], DateTime(2026, 3, 10, 12)).records, isEmpty);
  });

  group("ad hoc", () {
    test("records link within half an hour", () {
      final first = record(DateTime(2026, 3, 10, 10, 0), fiveMinutes);
      final second = record(DateTime(2026, 3, 10, 10, 25), fiveMinutes);
      final progress = adHoc([first, second], DateTime(2026, 3, 10, 10, 40));
      expect(progress.records, [first, second]);
      expect(progress.total(), const Duration(minutes: 10));
    });

    test("a longer gap starts a new block", () {
      final first = record(DateTime(2026, 3, 10, 10, 0), fiveMinutes);
      final second = record(DateTime(2026, 3, 10, 10, 40), fiveMinutes);
      final progress = adHoc([first, second], DateTime(2026, 3, 10, 10, 50));
      expect(progress.records, [second]);
    });

    test("the block is over half an hour after its last record", () {
      final first = record(DateTime(2026, 3, 10, 10, 0), fiveMinutes);
      expect(adHoc([first], DateTime(2026, 3, 10, 10, 25)).records, [first]);
      expect(adHoc([first], DateTime(2026, 3, 10, 10, 45)).records, isEmpty);
    });

    test("the same day does not link without a routine", () {
      final first = record(DateTime(2026, 3, 10, 8, 0), fiveMinutes);
      final second = record(DateTime(2026, 3, 10, 20, 0), fiveMinutes);
      expect(adHoc([first, second], DateTime(2026, 3, 10, 20, 10)).records, [
        second,
      ]);
    });
  });

  group("routine", () {
    test("records of the same day link no matter the gap", () {
      final first = record(
        DateTime(2026, 3, 10, 6, 0),
        fiveMinutes,
        routineEntryId: "a",
      );
      final second = record(
        DateTime(2026, 3, 10, 20, 0),
        fiveMinutes,
        routineEntryId: "b",
      );
      final progress = routine([first, second], DateTime(2026, 3, 10, 21, 0));
      expect(progress.records, [first, second]);
      expect(progress.byRoutineEntry(), {"a": fiveMinutes, "b": fiveMinutes});
    });

    test("a block of today stays current all day", () {
      final first = record(
        DateTime(2026, 3, 10, 6, 0),
        fiveMinutes,
        routineEntryId: "a",
      );
      expect(routine([first], DateTime(2026, 3, 10, 23, 0)).records, [first]);
    });

    test("across midnight only the window links", () {
      final evening = record(
        DateTime(2026, 3, 9, 22, 55),
        fiveMinutes,
        routineEntryId: "a",
      );
      final now = DateTime(2026, 3, 10, 1, 0);
      expect(routine([evening], now).records, [evening]);

      final earlier = record(
        DateTime(2026, 3, 9, 19, 55),
        fiveMinutes,
        routineEntryId: "a",
      );
      expect(routine([earlier], now).records, isEmpty);
    });

    test("twice the target duration widens the window", () {
      final evening = record(
        DateTime(2026, 3, 9, 19, 55),
        fiveMinutes,
        routineEntryId: "a",
      );
      expect(
        routine(
          [evening],
          DateTime(2026, 3, 10, 1, 0),
          target: const Duration(hours: 3),
        ).records,
        [evening],
      );
    });

    test("a midnight split stays in one block", () {
      final before = record(
        DateTime(2026, 3, 9, 23, 50),
        const Duration(minutes: 10),
        routineEntryId: "a",
      );
      final after = record(
        DateTime(2026, 3, 10, 0, 0),
        const Duration(minutes: 20),
        routineEntryId: "a",
      );
      final progress = routine([before, after], DateTime(2026, 3, 10, 0, 30));
      expect(
        progress.durationFor(exerciseId: "scales", routineEntryId: "a"),
        const Duration(minutes: 30),
      );
    });

    test("two devices' records on one day form one block", () {
      final phone = record(
        DateTime(2026, 3, 10, 7, 0),
        const Duration(minutes: 20),
        routineEntryId: "a",
      );
      final tablet = record(
        DateTime(2026, 3, 10, 7, 10),
        const Duration(minutes: 5),
        routineEntryId: "b",
      );
      final later = record(
        DateTime(2026, 3, 10, 18, 0),
        fiveMinutes,
        routineEntryId: "a",
      );
      final progress = routine([
        phone,
        tablet,
        later,
      ], DateTime(2026, 3, 10, 19, 0));
      expect(progress.records, [phone, tablet, later]);
      expect(progress.total(), const Duration(minutes: 30));
    });
  });

  group("running", () {
    test("a running record is always current", () {
      final running = record(
        DateTime(2026, 3, 8, 10, 0),
        fiveMinutes,
        runningSince: DateTime(2026, 3, 8, 10, 5),
      );
      final now = DateTime(2026, 3, 10, 12, 0);
      final progress = adHoc([running], now);
      expect(progress.records, [running]);
      expect(progress.running, running);
      expect(progress.total(), fiveMinutes);
      expect(
        progress.total(now: DateTime(2026, 3, 8, 10, 7)),
        fiveMinutes * 1.4,
      );
    });

    test("a running record counts up to now for its routine entry", () {
      final running = record(
        DateTime(2026, 3, 10, 10, 0),
        Duration.zero,
        routineEntryId: "a",
        runningSince: DateTime(2026, 3, 10, 10, 0),
      );
      final now = DateTime(2026, 3, 10, 10, 4);
      final progress = routine([running], now);
      expect(progress.byRoutineEntry()["a"], Duration.zero);
      expect(
        progress.byRoutineEntry(now: now)["a"],
        const Duration(minutes: 4),
      );
    });
  });

  test("records of another exercise are not counted for it", () {
    final scales = record(DateTime(2026, 3, 10, 10, 0), fiveMinutes);
    final other = record(
      DateTime(2026, 3, 10, 10, 5),
      fiveMinutes,
      exerciseId: "arpeggios",
    );
    final progress = adHoc([scales, other], DateTime(2026, 3, 10, 10, 15));
    expect(progress.durationFor(exerciseId: "scales"), fiveMinutes);
  });
}
