/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';

class ExerciseTile extends StatelessWidget {
  static const double badgeStripHeight = 22;

  final Exercise exercise;
  final Widget? leading;
  final Widget? trailing;

  final Widget? subtitle;

  final Widget? leadingBadge;

  final bool showCategory;
  final bool showBadges;
  final bool selected;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const ExerciseTile({
    super.key,
    required this.exercise,
    this.leading,
    this.trailing,
    this.subtitle,
    this.leadingBadge,
    this.showCategory = false,
    this.showBadges = true,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instrument = exercise.instrument;
    final category = exercise.category;
    final hasBadges =
        showBadges &&
        (leadingBadge != null ||
            instrument != null ||
            exercise.tags.isNotEmpty);
    return RoundedListTile(
      height: RoundedListTile.defaultHeight,
      leading: leading,
      title: exercise.name,
      selected: selected,
      subtitle:
          subtitle ??
          (!hasBadges
              ? null
              : SizedBox(
                  height: badgeStripHeight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 6,
                      children: [
                        ?leadingBadge,
                        if (leadingBadge != null &&
                            ((showCategory && category != null) ||
                                instrument != null ||
                                exercise.tags.isNotEmpty))
                          Container(
                            width: 1,
                            height: 14,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        if (showCategory && category != null)
                          Text(
                            category.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (showCategory &&
                            category != null &&
                            (instrument != null || exercise.tags.isNotEmpty))
                          Container(
                            width: 1,
                            height: 14,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        if (instrument != null)
                          CommonBadge(
                            name: instrument,
                            tooltip: false,
                            compact: true,
                          ),
                        if (instrument != null && exercise.tags.isNotEmpty)
                          Container(
                            width: 1,
                            height: 14,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        for (final tag in exercise.tags)
                          TagBadge(tag: tag, tooltip: false, compact: true),
                      ],
                    ),
                  ),
                )),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
