/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/surface.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';

class ExerciseDurationBar extends StatelessWidget {
  static const double _barHeight = 8;
  static const double _spacing = 4;
  static const double _lineHeight = 20;

  static const String deletedName = "Deleted exercise";

  /// Null for a deleted exercise.
  final String? name;
  final Duration duration;

  /// The duration the full width stands for.
  final Duration longest;

  const ExerciseDurationBar({
    super.key,
    required this.name,
    required this.duration,
    required this.longest,
  });

  static double heightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(_lineHeight) +
      _spacing +
      _barHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = longest > Duration.zero
        ? (duration.inMicroseconds / longest.inMicroseconds).clamp(0.0, 1.0)
        : 0.0;
    const radius = BorderRadius.all(Radius.circular(_barHeight / 2));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _spacing,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                name ?? deletedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: _lineHeight / 14,
                  fontStyle: name == null ? FontStyle.italic : null,
                ),
              ),
            ),
            Text(
              formatPracticed(duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Surface.raisedOf(context),
            borderRadius: radius,
          ),
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: fraction,
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
