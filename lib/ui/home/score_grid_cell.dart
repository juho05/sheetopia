/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/selection/selection_check_badge.dart';
import 'package:sheetopia/ui/common/selection/selection_gestures.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/common/text_scroll.dart';
import 'package:sheetopia/ui/home/thumbnail.dart';

class ScoreGridCell extends StatelessWidget {
  static const int width = 250;
  static const int height = 296;
  static final int thumbnailHeight = (height / 2.1).toInt();

  final Score score;
  final bool selecting;
  final void Function(Score score)? onScoreToggle;
  final void Function(Score score)? onScoreSelectionStart;
  final void Function(Score score)? onScoreRangeSelect;
  final bool selected;

  const ScoreGridCell({
    super.key,
    required this.score,
    this.selecting = false,
    this.onScoreToggle,
    this.onScoreSelectionStart,
    this.onScoreRangeSelect,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final gestures = SelectionGestures(
      item: score,
      selecting: selecting,
      onToggle: onScoreToggle,
      onSelectionStart: onScoreSelectionStart,
      onRangeSelect: onScoreRangeSelect,
      onActivate: () => context.go("/scores/${score.id}"),
    );

    return SizedBox(
      width: width.toDouble(),
      height: height.toDouble(),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: selected
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainer,
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: gestures.onTap,
          onLongPress: gestures.onLongPress,
          child: Builder(
            builder: (context) {
              final title = OptionalTooltip(
                message: score.title,
                child: TextScroll(
                  score.title,
                  fadedBorder: false,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              );
              final widget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Thumbnail(
                    score: score,
                    width: width,
                    height: thumbnailHeight,
                    devicePixelRatio: devicePixelRatio,
                    borderRadius: const BorderRadiusGeometry.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        title,
                        OptionalTooltip(
                          message: score.composer,
                          child: Text(
                            score.composer ?? "No composer",
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _BadgeStrip(
                            badges: [
                              for (final instrument in score.instruments)
                                CommonBadge(
                                  name: instrument,
                                  tooltip: false,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                            ],
                          ),
                        ),
                        if (score.tags.isNotEmpty) const Divider(),
                        _BadgeStrip(
                          badges: [
                            for (final tag in score.tags)
                              TagBadge(tag: tag, tooltip: false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
              if (selecting) {
                return Stack(
                  children: [
                    widget,
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SelectionCheckBadge(selected: selected),
                      ),
                    ),
                  ],
                );
              }
              return Stack(
                children: [
                  widget,
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SizedBox.square(
                        dimension: 34,
                        child: IconButton.filled(
                          color: Colors.white,
                          iconSize: 20,
                          padding: const EdgeInsets.all(0),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.black.withAlpha(100),
                            ),
                          ),
                          onPressed: () {
                            context.go("/scores/${score.id}/edit");
                          },
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  final List<Widget> badges;

  const _BadgeStrip({required this.badges});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(overscroll: false, scrollbars: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(spacing: 4, children: badges),
        ),
      ),
    );
  }
}
