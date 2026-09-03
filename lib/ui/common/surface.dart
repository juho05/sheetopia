/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

enum SurfaceLevel {
  page,
  pageTile,
  dialog,
  dialogTile;

  bool get onDialog => this == dialog || this == dialogTile;

  SurfaceLevel get tile => onDialog ? dialogTile : pageTile;
}

/// Tells descendants what they are painted on, so widgets shared between pages,
/// dialogs and tiles can pick colors that match their surroundings.
class Surface extends InheritedTheme {
  final SurfaceLevel level;

  const Surface({super.key, required this.level, required super.child});

  /// Marks [child] as the content of a tile or card on the current surface.
  static Widget tile(BuildContext context, {required Widget child}) =>
      Surface(level: levelOf(context).tile, child: child);

  static SurfaceLevel levelOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Surface>()?.level ??
      SurfaceLevel.page;

  /// The color the surrounding surface is painted with.
  static Color backgroundOf(BuildContext context) {
    final theme = Theme.of(context);
    return switch (levelOf(context)) {
      SurfaceLevel.page => theme.scaffoldBackgroundColor,
      SurfaceLevel.pageTile => theme.colorScheme.surfaceContainer,
      SurfaceLevel.dialog =>
        theme.dialogTheme.backgroundColor ??
            theme.colorScheme.surfaceContainerHigh,
      SurfaceLevel.dialogTile => _strongest(theme.colorScheme),
    };
  }

  /// The color for tiles, cards and other elements raised on the surrounding
  /// surface.
  static Color raisedOf(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (levelOf(context)) {
      SurfaceLevel.page => colors.surfaceContainer,
      SurfaceLevel.pageTile => colors.surfaceContainerHighest,
      SurfaceLevel.dialog => _strongest(colors),
      SurfaceLevel.dialogTile => colors.surfaceContainerHigh,
    };
  }

  /// The color for badges on the surrounding surface.
  static Color badgeOf(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return levelOf(context) == SurfaceLevel.page
        ? colors.surfaceContainerHigh
        : raisedOf(context);
  }

  /// The surface tone furthest from [ColorScheme.surface], one step beyond
  /// [ColorScheme.surfaceContainerHighest].
  static Color _strongest(ColorScheme colors) =>
      colors.brightness == Brightness.light
      ? colors.surfaceDim
      : colors.surfaceBright;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      Surface(level: level, child: child);

  @override
  bool updateShouldNotify(Surface oldWidget) => oldWidget.level != level;
}
