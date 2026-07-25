/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/common/text_scroll.dart';

void main() {
  Widget wrap(Widget child, {required double width}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: width, child: child)),
      ),
    );
  }

  String renderedText(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).data!;

  double offset(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(OverflowBox),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .getTranslation()
      .x;

  testWidgets("text that fits is neither duplicated nor animated", (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TextScroll("ab"), width: 500));
    await tester.pump(const Duration(seconds: 5));

    expect(renderedText(tester), "ab");
    expect(find.byType(OverflowBox), findsNothing);
  });

  testWidgets("text that overflows scrolls towards the start", (tester) async {
    await tester.pumpWidget(
      wrap(
        const TextScroll(
          "a title far too long to ever fit into the available space",
          delayBefore: Duration.zero,
          pauseBetween: null,
          numberOfReps: 1,
        ),
        width: 60,
      ),
    );
    await tester.pump(Duration.zero);
    await tester.pump();

    expect(find.byType(OverflowBox), findsOneWidget);
    expect(
      renderedText(tester),
      contains("a title far too long to ever fit into the available space"),
    );
    expect(offset(tester), 0);

    await tester.pump(const Duration(milliseconds: 500));
    final moved = offset(tester);
    expect(moved, lessThan(0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(offset(tester), lessThan(moved));

    await tester.pumpAndSettle();
  });

  testWidgets("a marquee stops once its repetitions are done", (tester) async {
    await tester.pumpWidget(
      wrap(
        const TextScroll(
          "a title far too long to ever fit into the available space",
          delayBefore: Duration.zero,
          pauseBetween: null,
          numberOfReps: 1,
        ),
        width: 60,
      ),
    );
    await tester.pumpAndSettle();

    expect(offset(tester), 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}