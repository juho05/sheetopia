/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';

class ExerciseCard extends StatelessWidget {
  static const double maxWidth = 640;

  final Exercise exercise;

  final bool scoresUnavailable;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.scoresUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = exercise.category;
    final instrument = exercise.instrument;
    final description = exercise.description;
    final hasBadges = instrument != null || exercise.tags.isNotEmpty;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              if (category != null)
                Text(
                  category.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasBadges)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (instrument != null)
                      CommonBadge(
                        name: instrument,
                        tooltip: false,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    for (final tag in exercise.tags)
                      TagBadge(tag: tag, tooltip: false),
                  ],
                ),
              if (description != null) ...[
                Divider(color: theme.colorScheme.outlineVariant),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
              ],
              if (scoresUnavailable)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(
                      Symbols.cloud_off,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Flexible(
                      child: Text(
                        "None of these scores are downloaded yet.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
