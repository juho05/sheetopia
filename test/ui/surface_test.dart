/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/surface.dart';

void main() {
  testWidgets("a dragged tile keeps the colors of the dialog", (tester) async {
    final theme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Surface(
            level: SurfaceLevel.dialog,
            child: ReorderableListView.builder(
              itemExtent: RoundedListTile.extentFor(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) =>
                  Material(type: MaterialType.transparency, child: child),
              itemCount: 3,
              itemBuilder: (context, index) => ReorderableDragStartListener(
                key: ValueKey(index),
                index: index,
                child: RoundedListTile(title: "Item $index", onTap: () {}),
              ),
              onReorder: (from, to) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("Item 0")),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump(const Duration(milliseconds: 50));

    final dragged = find.descendant(
      of: find.byType(RoundedListTile),
      matching: find.byType(Material),
    );
    expect(tester.widgetList<Material>(dragged).map((m) => m.color).toSet(), {
      theme.colorScheme.surfaceBright,
    }, reason: "the drag proxy renders outside the dialog");

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
