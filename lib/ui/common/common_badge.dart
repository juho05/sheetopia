/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

import 'optional_tooltip.dart';
import 'surface.dart';

class CommonBadge extends StatelessWidget {
  final String name;
  final Color? color;
  final Color? foreground;
  final IconData? trailingIcon;
  final bool compact;

  final bool tooltip;
  final void Function()? onTap;
  final void Function()? onRemove;

  const CommonBadge({
    super.key,
    required this.name,
    this.color,
    this.foreground,
    this.trailingIcon,
    this.compact = false,
    this.tooltip = true,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor =
        foreground ??
        (color != null
            ? color!.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white
            : null);
    final label = Text(
      name,
      style: (compact ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)!
          .copyWith(color: foregroundColor),
      overflow: TextOverflow.ellipsis,
    );
    Widget widget = Padding(
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 2, horizontal: 8)
          : const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: trailingIcon == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(child: label),
                Icon(
                  trailingIcon,
                  size: compact ? 12 : 14,
                  color: foregroundColor,
                ),
              ],
            ),
    );
    final backgroundColor = color ?? Surface.badgeOf(context);
    final borderRadius = BorderRadius.all(Radius.circular(compact ? 10 : 14));

    if (onTap != null) {
      widget = Material(
        borderRadius: borderRadius,
        color: backgroundColor,
        child: InkWell(borderRadius: borderRadius, onTap: onTap, child: widget),
      );
    } else {
      widget = DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: widget,
      );
    }

    if (onRemove != null) {
      widget = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 9, top: 7),
            child: widget,
          ),
          SizedBox.square(
            dimension: 22,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove),
              iconSize: 15,
              color: theme.colorScheme.onErrorContainer,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
              ),
              padding: const EdgeInsets.all(0),
            ),
          ),
        ],
      );
    }

    if (!tooltip) return widget;
    return OptionalTooltip(message: name, child: widget);
  }
}
