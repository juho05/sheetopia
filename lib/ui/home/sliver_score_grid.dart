/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';

class SliverScoreGrid extends StatelessWidget {
  static const double _gap = 12;

  final List<Score> scores;
  final double crossAxisExtent;

  final bool selectionMode;
  final void Function(Score score)? onScoreSelected;
  final void Function(Score score)? onScoreDeselected;
  final Set<String> selected;

  const SliverScoreGrid({
    super.key,
    required this.scores,
    required this.crossAxisExtent,
    this.selectionMode = false,
    this.onScoreSelected,
    this.onScoreDeselected,
    this.selected = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      final theme = Theme.of(context);
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            "No scores found.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final columns = max(
      ((crossAxisExtent - _gap) / (ScoreGridCell.width + _gap)).floor(),
      1,
    );
    return SliverFixedExtentList.builder(
      itemExtent: ScoreGridCell.height + _gap,
      itemCount: (scores.length / columns).ceil(),
      itemBuilder: (context, index) {
        final count = min(columns, scores.length - index * columns);
        return Padding(
          padding: const EdgeInsets.only(left: _gap, right: _gap, bottom: _gap),
          child: Row(
            mainAxisAlignment: columns == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            spacing: _gap,
            children: List.generate(count, (i) {
              i += columns * index;
              return ScoreGridCell(
                score: scores[i],
                onScoreTap: selectionMode
                    ? (score) {
                        if (selected.contains(score.id)) {
                          onScoreDeselected?.call(score);
                        } else {
                          onScoreSelected?.call(score);
                        }
                      }
                    : null,
                onScoreSelectionStart: onScoreSelected != null
                    ? (score) {
                        onScoreSelected!(score);
                      }
                    : null,
                selected: selected.contains(scores[i].id),
              );
            }),
          ),
        );
      },
    );
  }
}
