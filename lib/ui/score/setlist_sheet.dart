/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/home/thumbnail.dart';
import 'package:sheetopia/ui/setlists/setlist_navigation_viewmodel.dart';

class SetlistSheet extends StatefulWidget {
  final SetlistNavigationViewModel navigation;

  const SetlistSheet._({required this.navigation});

  static Future<void> show(
    BuildContext context, {
    required SetlistNavigationViewModel navigation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SetlistSheet._(navigation: navigation),
    );
  }

  @override
  State<SetlistSheet> createState() => _SetlistSheetState();
}

class _SetlistSheetState extends State<SetlistSheet> {
  static const double _thumbnailWidth = 120;
  static const double _thumbnailHeight = 160;
  static const double _spacing = 12;
  static const double _horizontalPadding = 16;

  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  double _centeredOffset(double viewportWidth) {
    final navigation = widget.navigation;
    final stride = _thumbnailWidth + _spacing;
    final contentWidth =
        _horizontalPadding * 2 + navigation.entries.length * stride - _spacing;
    final start = _horizontalPadding + navigation.index * stride;
    final offset = start + _thumbnailWidth / 2 - viewportWidth / 2;
    return offset.clamp(0.0, math.max(0.0, contentWidth - viewportWidth));
  }

  @override
  Widget build(BuildContext context) {
    final navigation = widget.navigation;
    final theme = Theme.of(context);
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      navigation.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    "${navigation.index + 1} of ${navigation.length}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _thumbnailHeight + 56,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _controller ??= ScrollController(
                    initialScrollOffset: _centeredOffset(constraints.maxWidth),
                  );
                  return ListView.separated(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                    ),
                    itemCount: navigation.entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: _spacing),
                    itemBuilder: (context, index) {
                      final entry = navigation.entries[index];
                      final score = entry.score;
                      final current = index == navigation.index;
                      return SizedBox(
                        key: ValueKey(index),
                        width: _thumbnailWidth,
                        child: Opacity(
                          opacity: entry.playable ? 1 : 0.4,
                          child: InkWell(
                            onTap: entry.playable
                                ? () {
                                    navigation.jumpTo(index);
                                    Navigator.pop(context);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 6,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: current
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 4,
                                    ),
                                  ),
                                  child: score == null
                                      ? Container(
                                          width: _thumbnailWidth,
                                          height: _thumbnailHeight,
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.music_off,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        )
                                      : Thumbnail(
                                          score: score,
                                          width: _thumbnailWidth.toInt(),
                                          height: _thumbnailHeight.toInt(),
                                          devicePixelRatio: devicePixelRatio,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                ),
                                Text(
                                  score?.title ?? "Unavailable",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: current
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
