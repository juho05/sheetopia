/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';

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
  }) : assert(onTap == null || onRemove == null);

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
    final iconSize = compact ? 12.0 : 14.0;
    final onRemove = this.onRemove;
    Widget widget = Padding(
      padding: compact
          ? EdgeInsets.fromLTRB(8, 2, onRemove == null ? 8 : 2, 2)
          : EdgeInsets.fromLTRB(12, 6, onRemove == null ? 12 : 4, 6),
      child: trailingIcon == null && onRemove == null
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(child: label),
                if (trailingIcon != null)
                  Icon(trailingIcon, size: iconSize, color: foregroundColor),
                if (onRemove != null)
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: iconSize,
                      color: foregroundColor,
                    ),
                  ),
              ],
            ),
    );
    final backgroundColor = color ?? Surface.badgeOf(context);
    final borderRadius = BorderRadius.all(Radius.circular(compact ? 10 : 14));

    final onPressed = onTap ?? onRemove;
    if (onPressed != null) {
      widget = Material(
        borderRadius: borderRadius,
        color: backgroundColor,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onPressed,
          child: widget,
        ),
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

    if (!tooltip) return widget;
    return OptionalTooltip(message: name, child: widget);
  }
}
