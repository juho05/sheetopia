/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/edit_score/source_input_dialog.dart';

void main() {
  const options = ["IMSLP", "Musescore"];

  Future<Iterable<String>> getOptions(String filter) async {
    return options
        .where((o) => o.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  Finder sourceField() => find.byType(TextField).first;

  Finder linkField() => find.byType(TextField).last;

  Future<void> openDialog(
    WidgetTester tester, {
    bool enableClear = false,
    void Function(({String source, String sourceLink})? result)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await SourceInputDialog.show(
                  context,
                  title: "Edit source",
                  submitBtnText: "Save",
                  enableClear: enableClear,
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

  testWidgets("a link without a source blocks submitting", (tester) async {
    await openDialog(tester);

    await tester.enterText(linkField(), "https://imslp.org");
    await tester.pumpAndSettle();

    expect(find.text("Required"), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(find.byType(SourceInputDialog), findsOneWidget);
  });

  testWidgets("an empty source cannot be submitted", (tester) async {
    await openDialog(tester);

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(find.byType(SourceInputDialog), findsOneWidget);
  });

  testWidgets("an empty source clears where clearing is enabled", (
    tester,
  ) async {
    ({String source, String sourceLink})? result;
    await openDialog(
      tester,
      enableClear: true,
      onResult: (value) => result = value,
    );

    expect(find.widgetWithText(FilledButton, "Save"), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, "Clear"));
    await tester.pumpAndSettle();

    expect(find.byType(SourceInputDialog), findsNothing);
    expect(result, (source: "", sourceLink: ""));
  });

  testWidgets("the returned pair is trimmed", (tester) async {
    ({String source, String sourceLink})? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.enterText(sourceField(), "  IMSLP  ");
    await tester.enterText(linkField(), "  https://imslp.org  ");
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(result, (source: "IMSLP", sourceLink: "https://imslp.org"));
  });

  testWidgets("only http(s) links can be submitted", (tester) async {
    await openDialog(tester);
    await tester.enterText(sourceField(), "IMSLP");

    for (final link in [
      "not a link",
      "imslp.org/wiki/Main_Page",
      "javascript:alert(1)",
      "file:///etc/passwd",
      "mailto:someone@example.com",
      "https://",
    ]) {
      await tester.enterText(linkField(), link);
      await tester.pumpAndSettle();

      expect(
        find.text("Must be an http(s) link"),
        findsOneWidget,
        reason: link,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
        reason: link,
      );
    }
  });

  testWidgets("a link with a port is accepted", (tester) async {
    ({String source, String sourceLink})? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.enterText(sourceField(), "Local");
    await tester.enterText(linkField(), "http://localhost:8080/scores/1");
    await tester.pumpAndSettle();

    expect(find.text("Must be an http(s) link"), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(result, (
      source: "Local",
      sourceLink: "http://localhost:8080/scores/1",
    ));
  });

  testWidgets("each field clears through its suffix button", (tester) async {
    await openDialog(tester);

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(sourceField(), "IMSLP");
    await tester.enterText(linkField(), "https://imslp.org");
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.clear), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.clear).last);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(linkField()).controller!.text, "");
    expect(tester.widget<TextField>(sourceField()).controller!.text, "IMSLP");

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(sourceField()).controller!.text, "");
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
