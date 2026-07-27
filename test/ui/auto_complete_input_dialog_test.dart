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
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';

void main() {
  const options = ["Bach", "Beethoven", "Brahms"];

  Future<Iterable<String>> getOptions(String filter) async {
    return options
        .where((o) => o.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  Finder suggestion(String option) => find.widgetWithText(CommonBadge, option);

  Future<void> openDialog(
    WidgetTester tester, {
    void Function(String? result)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await AutoCompleteInputDialog.show(
                  context,
                  title: "Add composer",
                  inputLabel: "Composer",
                  submitBtnText: "Add",
                  getOptions: getOptions,
                );
                onResult?.call(result);
              },
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
  }

  testWidgets("tapping a suggestion fills the field without submitting", (
    tester,
  ) async {
    await openDialog(tester);

    await tester.tap(suggestion("Brahms"));
    await tester.pumpAndSettle();

    expect(find.byType(AutoCompleteInputDialog), findsOneWidget);
    expect(find.text("Brahms"), findsOneWidget);
  });

  testWidgets("enter submits while the field is unfocused", (tester) async {
    String? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.tap(suggestion("Brahms"));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<EditableTextState>(find.byType(EditableText))
          .widget
          .focusNode
          .hasFocus,
      isFalse,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AutoCompleteInputDialog), findsNothing);
    expect(result, "Brahms");
  });

  testWidgets("enter submits once while the field is focused", (tester) async {
    String? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.enterText(find.byType(TextField), "Mozart");
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AutoCompleteInputDialog), findsNothing);
    expect(result, "Mozart");
    // a second pop would have taken the page underneath with it
    expect(find.text("open"), findsOneWidget);
  });

  testWidgets("enter on a focused suggestion selects instead of submitting", (
    tester,
  ) async {
    await openDialog(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AutoCompleteInputDialog), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Bach",
    );
  });

  testWidgets("enter does nothing on an empty field", (tester) async {
    await openDialog(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AutoCompleteInputDialog), findsOneWidget);
  });
}
