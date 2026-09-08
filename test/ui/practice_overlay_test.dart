/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/practice/practice_overlay.dart';
import 'package:sheetopia/ui/practice/practice_timer.dart';

void main() {
  Future<void> pumpRecovery(
    WidgetTester tester,
    PracticeRecovery recovery,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            PracticeRecoveryOverlay(
              exerciseName: "Chromatic",
              recovery: recovery,
              onChoice: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  testWidgets("counting until now follows the clock, not the gap it was "
      "raised with", (tester) async {
    await pumpRecovery(
      tester,
      PracticeRecovery(
        counted: const Duration(minutes: 2),
        leftAt: DateTime.now().subtract(const Duration(minutes: 30)),
        // stale on purpose, the button writes the time of the tap
        gap: const Duration(minutes: 1),
      ),
    );

    expect(find.text("Count 2:00"), findsOneWidget);
    expect(find.text("Count 32:00"), findsOneWidget);
    expect(find.text("Count 3:00"), findsNothing);
  });

  testWidgets("the choices say what each one keeps", (tester) async {
    await pumpRecovery(
      tester,
      PracticeRecovery(
        counted: const Duration(minutes: 4),
        leftAt: DateTime.now().subtract(const Duration(minutes: 6)),
        gap: const Duration(minutes: 6),
      ),
    );

    expect(find.text("Count 4:00"), findsOneWidget);
    expect(find.text("Count 10:00"), findsOneWidget);
    expect(find.text("Count nothing"), findsOneWidget);
    expect(
      find.text("Drops all 4:00 of Chromatic from this session."),
      findsOneWidget,
    );
    expect(find.textContaining("waits to be resumed"), findsOneWidget);
    expect(find.textContaining("keeps running"), findsOneWidget);
  });

  testWidgets("with nothing counted yet, discarding says so", (tester) async {
    await pumpRecovery(
      tester,
      PracticeRecovery(
        counted: Duration.zero,
        leftAt: DateTime.now().subtract(const Duration(minutes: 6)),
        gap: const Duration(minutes: 6),
      ),
    );

    expect(find.text("Count 0:00"), findsOneWidget);
    expect(
      find.text("Nothing is recorded for Chromatic in this session."),
      findsOneWidget,
    );
  });

  testWidgets("a stopwatch left on another day names the day", (tester) async {
    await pumpRecovery(
      tester,
      PracticeRecovery(
        counted: const Duration(minutes: 4),
        leftAt: DateTime.now().subtract(const Duration(days: 1)),
        gap: const Duration(days: 1),
      ),
    );

    expect(find.textContaining("yesterday at"), findsOneWidget);
  });
}
