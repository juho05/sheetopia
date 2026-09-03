/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class ExerciseScoreSelector extends StatelessWidget {
  final List<Score> scores;
  final int selectedIndex;
  final void Function(int index) onSelected;

  const ExerciseScoreSelector({
    super.key,
    required this.scores,
    required this.selectedIndex,
    required this.onSelected,
  });

  bool get _enabled => scores.length > 1;

  String get _title => selectedIndex < 0 || selectedIndex >= scores.length
      ? ""
      : scores[selectedIndex].title;

  Future<void> _select(BuildContext context) async {
    final index = await _SelectScoreDialog.show(
      context,
      scores: scores,
      selectedIndex: selectedIndex,
    );
    if (index == null) return;
    onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(
      _title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall,
    );

    if (!_enabled) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: title,
      );
    }

    return Tooltip(
      message: "Select score",
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _select(context),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
              top: 3,
              bottom: 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: title),
                Icon(
                  Symbols.arrow_drop_down,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectScoreDialog extends StatelessWidget {
  static const int _maxVisibleScores = 6;

  final List<Score> scores;
  final int selectedIndex;

  const _SelectScoreDialog({required this.scores, required this.selectedIndex});

  static Future<int?> show(
    BuildContext context, {
    required List<Score> scores,
    required int selectedIndex,
  }) {
    return showSheetopiaDialog<int>(
      context: context,
      builder: (context) =>
          _SelectScoreDialog(scores: scores, selectedIndex: selectedIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extent = RoundedListTile.extentFor();
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            "Select score",
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: min(scores.length, _maxVisibleScores + 0.5) * extent,
              ),
              child: ListView.builder(
                itemExtent: extent,
                padding: EdgeInsets.zero,
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  final score = scores[index];
                  final playable = score.file != null;
                  return RoundedListTile(
                    title: score.title,
                    selected: index == selectedIndex,
                    onTap: playable
                        ? () => Navigator.pop(context, index)
                        : null,
                    trailing: playable
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Symbols.cloud_off,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ),
        ],
      ),
    );
  }
}
