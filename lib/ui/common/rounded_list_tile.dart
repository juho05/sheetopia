/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/surface.dart';

class RoundedListTile extends StatelessWidget {
  static const double spacing = 8;
  static const double compactHeight = 48;
  static const double defaultHeight = 64;
  static const double horizontalMargin = 12;

  static double extentFor({bool subtitle = false}) =>
      (subtitle ? defaultHeight : compactHeight) + spacing;

  final String title;
  final TextStyle? titleStyle;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final bool selected;
  final Color? color;
  final bool tooltip;

  final double? height;

  const RoundedListTile({
    super.key,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.color,
    this.tooltip = true,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const borderRadius = BorderRadius.all(Radius.circular(16));
    final trailing = this.trailing;
    final leading = this.leading;
    final subtitle = this.subtitle;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: spacing / 2,
      ),
      child: Material(
        color:
            color ??
            (selected
                ? theme.colorScheme.secondaryContainer
                : Surface.raisedOf(context)),
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height:
                height ?? (subtitle == null ? compactHeight : defaultHeight),
            child: Padding(
              padding: EdgeInsets.only(
                left: leading == null ? 16 : 12,
                right: trailing == null ? 16 : 4,
              ),
              child: Row(
                spacing: 12,
                children: [
                  if (leading != null)
                    IconTheme.merge(
                      data: IconThemeData(
                        color: selected
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      child: leading,
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        DefaultTextStyle.merge(
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(
                                color: selected
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onSurface,
                              )
                              .merge(titleStyle),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          child: OptionalTooltip(
                            message: tooltip ? title : null,
                            child: Text(title),
                          ),
                        ),
                        if (subtitle != null)
                          DefaultTextStyle.merge(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            child: subtitle,
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Surface.tile(context, child: tile);
  }
}
