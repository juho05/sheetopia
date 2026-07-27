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
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/common_badge.dart';

void main() {
  const options = ["Bach", "Beethoven", "Brahms"];

  Future<Iterable<String>> getOptions(String filter) async {
    return options
        .where((o) => o.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  Finder suggestion(String option) => find.widgetWithText(CommonBadge, option);

  String? focusedSuggestion() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<CommonBadge>()?.name;
  }

  bool fieldHasFocus(WidgetTester tester) => tester
      .state<EditableTextState>(find.byType(EditableText))
      .widget
      .focusNode
      .hasFocus;

  Widget wrap({
    void Function(String option)? onSelected,
    VoidCallback? onSubmitPressed,
    bool clearButton = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AutoCompleteField(
              autofocus: true,
              getOptions: getOptions,
              onSelected: onSelected,
              decoration: InputDecoration(
                suffixIcon: clearButton
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {},
                      )
                    : null,
              ),
            ),
            FilledButton(
              onPressed: onSubmitPressed ?? () {},
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets("suggestions only show while the field has focus", (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(suggestion("Bach"), findsOneWidget);

    tester
        .state<EditableTextState>(find.byType(EditableText))
        .widget
        .focusNode
        .unfocus();
    await tester.pumpAndSettle();

    expect(suggestion("Bach"), findsNothing);
  });

  testWidgets("suggestions never cover the controls below the field", (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(wrap(onSubmitPressed: () => pressed = true));
    await tester.pumpAndSettle();

    expect(suggestion("Beethoven"), findsOneWidget);

    await tester.tap(find.text("Submit"));
    expect(pressed, isTrue);
  });

  testWidgets("typing filters the suggestions and drops an exact match", (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "bee");
    await tester.pumpAndSettle();

    expect(suggestion("Beethoven"), findsOneWidget);
    expect(suggestion("Bach"), findsNothing);

    await tester.enterText(find.byType(TextField), "Beethoven");
    await tester.pumpAndSettle();

    expect(suggestion("Beethoven"), findsNothing);
  });

  testWidgets("tapping a suggestion fills the field and unfocuses it", (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(wrap(onSelected: (option) => selected = option));
    await tester.pumpAndSettle();

    await tester.tap(suggestion("Brahms"));
    await tester.pumpAndSettle();

    expect(selected, "Brahms");
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Brahms",
    );
    expect(fieldHasFocus(tester), isFalse);
    expect(suggestion("Bach"), findsNothing);
  });

  testWidgets("tab walks through the suggestions and back", (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Bach");
    expect(suggestion("Bach"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Beethoven");

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Bach");
  });

  testWidgets("arrow keys walk through the suggestions and back", (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Bach");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Beethoven");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(focusedSuggestion(), "Bach");

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets("arrow down skips focusable decorations of the field", (
    tester,
  ) async {
    await tester.pumpWidget(wrap(clearButton: true));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(focusedSuggestion(), "Bach");
  });

  testWidgets("arrow down moves the caret while there are no suggestions", (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Mozart");
    await tester.pumpAndSettle();
    expect(suggestion("Bach"), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(fieldHasFocus(tester), isTrue);
  });

  testWidgets("a focused suggestion is selected with enter", (tester) async {
    String? selected;
    await tester.pumpWidget(wrap(onSelected: (option) => selected = option));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, "Bach");
    expect(suggestion("Beethoven"), findsNothing);
    expect(fieldHasFocus(tester), isFalse);
  });
}
