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

class SelectTagsList extends StatelessWidget {
  final Iterable<Widget> tags;
  final void Function() onAdd;

  const SelectTagsList({super.key, required this.tags, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 4,
      runSpacing: 4,
      children: tags.followedBy([_AddBadge(onTap: onAdd)]).toList(),
    );
  }
}

class _AddBadge extends StatelessWidget {
  final void Function()? onTap;

  const _AddBadge({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget widget = Padding(
      padding: const EdgeInsets.only(left: 6, right: 10, top: 1, bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          const Icon(Icons.add, size: 16),
          Flexible(
            child: Text(
              "Add",
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      widget = InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: widget,
      );
    }
    widget = DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(1),
        dashPattern: [5, 5],
        strokeWidth: 2,
        color: theme.colorScheme.onSurface.withAlpha(160),
      ),
      child: widget,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 7),
      child: OptionalTooltip(message: "Add", child: widget),
    );
  }
}
