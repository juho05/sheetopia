/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/common/fab_menu.dart';

void main() {
  Future<void> pumpMenu(
    WidgetTester tester,
    List<FabMenuItem> items, {
    bool extended = false,
    Widget? label,
    Widget? icon,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: extended
              ? FabMenu.extended(items: items, label: label, icon: icon)
              : FabMenu(items: items, icon: icon, tooltip: "Add"),
        ),
      ),
    );
  }

  testWidgets("the menu opens and closes on tapping the fab", (tester) async {
    await pumpMenu(tester, [
      FabMenuItem(label: "First", icon: Icons.add, onPressed: () {}),
      FabMenuItem(label: "Second", icon: Icons.edit, onPressed: () {}),
    ]);
    expect(find.text("First"), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text("First"), findsOneWidget);
    expect(find.text("Second"), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text("First"), findsNothing);
  });

  testWidgets("selecting an item closes the menu and reports it", (
    tester,
  ) async {
    var selected = "";
    await pumpMenu(tester, [
      FabMenuItem(label: "First", onPressed: () => selected = "First"),
      FabMenuItem(label: "Second", onPressed: () => selected = "Second"),
    ]);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Second"));
    await tester.pumpAndSettle();

    expect(selected, "Second");
    expect(find.text("Second"), findsNothing);
  });

  testWidgets("tapping outside closes the menu", (tester) async {
    await pumpMenu(tester, [
      FabMenuItem(label: "First", onPressed: () {}),
      FabMenuItem(label: "Second", onPressed: () {}),
    ]);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text("First"), findsNothing);
  });

  testWidgets("disabled items are not selectable", (tester) async {
    var taps = 0;
    await pumpMenu(tester, [
      FabMenuItem(label: "First", onPressed: () => taps++),
      const FabMenuItem(label: "Second", onPressed: null),
    ]);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Second"));
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(find.text("Second"), findsOneWidget);
  });

  testWidgets("a single item collapses into a regular fab", (tester) async {
    var taps = 0;
    await pumpMenu(tester, [
      FabMenuItem(label: "Only", icon: Icons.edit, onPressed: () => taps++),
    ]);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text("Only"), findsNothing);
  });

  testWidgets("a single item fills in an unspecified icon and label", (
    tester,
  ) async {
    await pumpMenu(tester, [
      FabMenuItem(label: "Only", icon: Icons.edit, onPressed: () {}),
    ], extended: true);

    expect(find.text("Only"), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets("an explicit icon and label win over the single item", (
    tester,
  ) async {
    await pumpMenu(
      tester,
      [FabMenuItem(label: "Only", icon: Icons.edit, onPressed: () {})],
      extended: true,
      label: const Text("Add"),
      icon: const Icon(Icons.playlist_add),
    );

    expect(find.text("Add"), findsOneWidget);
    expect(find.text("Only"), findsNothing);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets("the fab icon defaults to add", (tester) async {
    await pumpMenu(tester, [
      FabMenuItem(label: "Only", onPressed: () {}),
    ]);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets("without items the fab is disabled", (tester) async {
    await pumpMenu(tester, []);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNull);
  });

  testWidgets("the extended variant collapses while open", (tester) async {
    await pumpMenu(
      tester,
      [
        FabMenuItem(label: "First", icon: Icons.add, onPressed: () {}),
        FabMenuItem(label: "Second", icon: Icons.edit, onPressed: () {}),
      ],
      extended: true,
      label: const Text("Add scores"),
    );
    final fab = find.byType(FloatingActionButton);
    expect(tester.getSize(fab).width, greaterThan(56));

    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(tester.getSize(fab), const Size(56, 56));

    await tester.tap(fab);
    await tester.pumpAndSettle();
    expect(tester.getSize(fab).width, greaterThan(56));
  });
}
