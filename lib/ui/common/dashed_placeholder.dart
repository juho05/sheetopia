/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:dotted_border/dotted_border.dart';
import 'package:material_ui/material_ui.dart';

/// Dashed area that holds the buttons to add something.
class DashedPlaceholder extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const DashedPlaceholder({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(16),
        padding: const EdgeInsets.all(1),
        dashPattern: const [6, 6],
        strokeWidth: 2,
        color: theme.colorScheme.onSurface.withAlpha(160),
      ),
      child: Padding(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, minHeight: 40),
            child: child,
          ),
        ),
      ),
    );
  }
}
