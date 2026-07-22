/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, bool visible, VoidCallback tap) {
    return tester.pumpWidget(
      MaterialApp(
        home: FadingOverlay(
          visible: visible,
          child: ElevatedButton(onPressed: tap, child: const Text("Tap")),
        ),
      ),
    );
  }

  testWidgets("a visible overlay is tappable", (tester) async {
    var taps = 0;
    await pumpButton(tester, true, () => taps++);
    await tester.tap(find.text("Tap"));
    expect(taps, 1);
  });

  testWidgets("a hidden overlay is not tappable", (tester) async {
    var taps = 0;
    await pumpButton(tester, false, () => taps++);
    await tester.tap(find.text("Tap"), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets("hit-testing stops at the start of the fade out", (tester) async {
    var taps = 0;
    await pumpButton(tester, true, () => taps++);
    await pumpButton(tester, false, () => taps++);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(find.text("Tap"), warnIfMissed: false);
    expect(taps, 0);
  });
}
