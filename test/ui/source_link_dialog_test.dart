/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/edit_score/source_link_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    String link = "",
    void Function(String? result)? onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await SourceLinkDialog.show(context, link: link);
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

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets("an empty link cannot be submitted", (tester) async {
    await openDialog(tester);

    expect(submitButton(tester).onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(find.byType(SourceLinkDialog), findsOneWidget);
  });

  testWidgets("emptying an existing link removes it", (tester) async {
    String? result;
    await openDialog(
      tester,
      link: "https://imslp.org",
      onResult: (value) => result = value,
    );

    await tester.tap(find.byTooltip("Clear"));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Remove"));
    await tester.pumpAndSettle();

    expect(find.byType(SourceLinkDialog), findsNothing);
    expect(result, "");
  });

  testWidgets("the returned link is trimmed", (tester) async {
    String? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.enterText(find.byType(TextField), "  https://imslp.org  ");
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(result, "https://imslp.org");
  });

  testWidgets("only http(s) links can be submitted", (tester) async {
    await openDialog(tester);

    for (final link in [
      "not a link",
      "imslp.org/wiki/Main_Page",
      "javascript:alert(1)",
      "file:///etc/passwd",
      "mailto:someone@example.com",
      "https://",
    ]) {
      await tester.enterText(find.byType(TextField), link);
      await tester.pumpAndSettle();

      expect(
        find.text("Must be an http(s) link"),
        findsOneWidget,
        reason: link,
      );
      expect(submitButton(tester).onPressed, isNull, reason: link);
    }
  });

  testWidgets("a link with a port is accepted", (tester) async {
    String? result;
    await openDialog(tester, onResult: (value) => result = value);

    await tester.enterText(
      find.byType(TextField),
      "http://localhost:8080/scores/1",
    );
    await tester.pumpAndSettle();

    expect(find.text("Must be an http(s) link"), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, "Save"));
    await tester.pumpAndSettle();

    expect(result, "http://localhost:8080/scores/1");
  });
}
