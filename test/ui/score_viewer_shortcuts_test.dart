/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors the focus arrangement of ScoreViewer: the page turn shortcuts sit
// above a single autofocused scope that holds both the file view and the
// overlay buttons. PdfView itself cannot be pumped here because pdfrx needs a
// native library, so this guards the arrangement rather than the real widget.
void main() {
  late List<String> log;
  late FocusNode buttonFocus;

  Widget viewer({Widget? fileView}) {
    return MaterialApp(
      home: Scaffold(
        body: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                log.add("prev"),
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                log.add("next"),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                log.add("prev"),
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                log.add("next"),
            const SingleActivator(LogicalKeyboardKey.pageUp): () =>
                log.add("prev"),
            const SingleActivator(LogicalKeyboardKey.pageDown): () =>
                log.add("next"),
            const SingleActivator(LogicalKeyboardKey.space): () =>
                log.add("next"),
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                log.add("next"),
            const SingleActivator(LogicalKeyboardKey.backspace): () =>
                log.add("prev"),
          },
          child: FocusScope(
            autofocus: true,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      fileView ?? const SizedBox.expand(),
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          focusNode: buttonFocus,
                          icon: const BackButtonIcon(),
                          onPressed: () => log.add("back"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    log = <String>[];
    buttonFocus = FocusNode();
  });

  tearDown(() => buttonFocus.dispose());

  testWidgets("every page key reaches the shortcuts", (tester) async {
    await tester.pumpWidget(viewer());
    expect(
      FocusManager.instance.primaryFocus,
      isA<FocusScopeNode>(),
      reason: "the file view holds no focus scope of its own",
    );

    for (final key in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.backspace,
    ]) {
      await tester.sendKeyEvent(key);
    }

    expect(log, [
      "prev",
      "next",
      "prev",
      "next",
      "prev",
      "next",
      "next",
      "next",
      "prev",
    ]);
  });

  testWidgets("page keys still work once an overlay button took focus", (
    tester,
  ) async {
    await tester.pumpWidget(viewer());

    buttonFocus.requestFocus();
    await tester.pump();
    expect(buttonFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

    expect(log, ["next"], reason: "the button is inside the shortcut scope");
  });

  testWidgets("a nested scope in the file view does not swallow keys", (
    tester,
  ) async {
    await tester.pumpWidget(
      viewer(
        fileView: const FocusScope(autofocus: true, child: SizedBox.expand()),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

    expect(log, ["next"]);
  });
}
