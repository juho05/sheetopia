/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/practice/routine_play_viewmodel.dart';
import 'package:sheetopia/ui/score/chrome/play_toolbar.dart';
import 'package:sheetopia/ui/score/chrome/sequence_bubble.dart';
import 'package:sheetopia/ui/score/chrome/sequence_sheet.dart';
import 'package:sheetopia/ui/score/score_viewer.dart';

class RoutinePlayPage extends StatefulWidget {
  final String routineId;
  final int? startIndex;

  const RoutinePlayPage({super.key, required this.routineId, this.startIndex});

  @override
  State<RoutinePlayPage> createState() => _RoutinePlayPageState();
}

class _RoutinePlayPageState extends State<RoutinePlayPage> {
  late final RoutinePlayViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RoutinePlayViewModel(
      repo: context.read(),
      scoresRepo: context.read(),
      routineId: widget.routineId,
      startIndex: widget.startIndex,
    )..addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    if (_viewModel.deleted) {
      context.go("/");
      return;
    }
    setState(() {});
  }

  void _openSheet() {
    SequenceSheet.show(
      context,
      title: _viewModel.name,
      items: [
        for (final entry in _viewModel.entries)
          SequenceSheetItem(score: entry.score, title: entry.exercise.name),
      ],
      currentIndex: _viewModel.position,
      onSelect: _viewModel.jumpTo,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_viewModel.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(
                _viewModel.length == 0
                    ? "This routine has no exercises."
                    : "None of these exercises have a downloaded score.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text("Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewModel.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final scoreId = _viewModel.currentScoreId;
    if (scoreId == null) return _buildEmpty(context);
    return ScoreViewer(
      initialScoreId: scoreId,
      sequence: _viewModel,
      onSwipeUp: _openSheet,
      topOverlay: SequenceBubble(
        name: _viewModel.exerciseName,
        index: _viewModel.position,
        length: _viewModel.length,
        onTap: _openSheet,
      ),
      bottomBar: PlayToolbar(
        leading: [
          IconButton(
            tooltip: "Previous exercise",
            onPressed: _viewModel.hasPrevious ? _viewModel.previous : null,
            icon: const Icon(Symbols.skip_previous),
          ),
        ],
        center: ExerciseScoreSelector(
          scores: _viewModel.scores,
          selectedIndex: _viewModel.scoreIndex,
          onSelected: _viewModel.selectScore,
        ),
        trailing: [
          IconButton(
            tooltip: "Next exercise",
            onPressed: _viewModel.hasNext ? _viewModel.next : null,
            icon: const Icon(Symbols.skip_next),
          ),
        ],
      ),
    );
  }
}
