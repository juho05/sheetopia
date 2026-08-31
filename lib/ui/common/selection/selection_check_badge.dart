/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class SelectionCheckBadge extends StatelessWidget {
  static const double size = 28;

  final bool selected;

  const SelectionCheckBadge({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? theme.colorScheme.primary
              : Colors.black.withAlpha(100),
          border: selected
              ? null
              : const Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
            : null,
      ),
    );
  }
}
