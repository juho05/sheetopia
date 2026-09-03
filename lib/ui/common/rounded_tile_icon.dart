/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/surface.dart';

class RoundedTileIcon extends StatelessWidget {
  static const double size = 40;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(10),
  );

  final IconData? icon;
  final Widget? child;
  final Color? color;
  final Color? iconColor;

  const RoundedTileIcon({
    super.key,
    this.icon,
    this.child,
    this.color,
    this.iconColor,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: size,
      child: Material(
        color: color ?? Surface.raisedOf(context),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child:
            child ??
            Icon(
              icon,
              size: 22,
              color: iconColor ?? theme.colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
