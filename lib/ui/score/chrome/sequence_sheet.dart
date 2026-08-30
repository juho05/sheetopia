/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/home/thumbnail.dart';

class SequenceSheetItem {
  final Score? score;
  final String title;

  const SequenceSheetItem({required this.score, required this.title});

  bool get playable => score?.file != null;
}

class SequenceSheet extends StatefulWidget {
  final String title;
  final List<SequenceSheetItem> items;
  final int currentIndex;
  final void Function(int index) onSelect;

  const SequenceSheet._({
    required this.title,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<SequenceSheetItem> items,
    required int currentIndex,
    required void Function(int index) onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SequenceSheet._(
        title: title,
        items: items,
        currentIndex: currentIndex,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<SequenceSheet> createState() => _SequenceSheetState();
}

class _SequenceSheetState extends State<SequenceSheet> {
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
    final stride = _thumbnailWidth + _spacing;
    final contentWidth =
        _horizontalPadding * 2 + widget.items.length * stride - _spacing;
    final start = _horizontalPadding + widget.currentIndex * stride;
    final offset = start + _thumbnailWidth / 2 - viewportWidth / 2;
    return offset.clamp(0.0, math.max(0.0, contentWidth - viewportWidth));
  }

  @override
  Widget build(BuildContext context) {
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
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    "${widget.currentIndex + 1} of ${widget.items.length}",
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
                    itemCount: widget.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: _spacing),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final score = item.score;
                      final current = index == widget.currentIndex;
                      return SizedBox(
                        key: ValueKey(index),
                        width: _thumbnailWidth,
                        child: Opacity(
                          opacity: item.playable ? 1 : 0.4,
                          child: InkWell(
                            onTap: item.playable
                                ? () {
                                    widget.onSelect(index);
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
                                  item.title,
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
