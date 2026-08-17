/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';

class DashedBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final void Function()? onTap;

  const DashedBadge({
    super.key,
    this.label = "Add",
    this.icon = Icons.add,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget widget = Padding(
      padding: const EdgeInsets.only(left: 8, right: 12, top: 3, bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          Icon(icon, size: 16),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      widget = InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: widget,
      );
    }
    widget = DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(14),
        padding: const EdgeInsets.all(1),
        dashPattern: [5, 5],
        strokeWidth: 2,
        color: theme.colorScheme.onSurface.withAlpha(160),
      ),
      child: widget,
    );

    return OptionalTooltip(message: label, child: widget);
  }
}
