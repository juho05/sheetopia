/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/practice/exercise_card.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/practice/routine_play_viewmodel.dart';
import 'package:sheetopia/ui/score/chrome/full_screen_button.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';
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
          SequenceSheetItem(
            score: entry.score,
            title: entry.exercise.name,
            playable: true,
          ),
      ],
      currentIndex: _viewModel.position,
      onSelect: _viewModel.jumpTo,
    );
  }

  Widget _buildToolbar(BuildContext context, {required bool showScores}) {
    final session = PlaySession.of(context);
    return PlayToolbar(
      leading: [
        OutlinedButton(
          onPressed: _viewModel.hasPrevious ? _viewModel.previous : null,
          child: const Text("Prev"),
        ),
      ],
      center: showScores
          ? ExerciseScoreSelector(
              scores: _viewModel.scores,
              selectedIndex: _viewModel.scoreIndex,
              onSelected: _viewModel.selectScore,
            )
          : null,
      trailing: [
        FilledButton(
          onPressed: _viewModel.hasNext
              ? _viewModel.next
              : () {
                  if (!Platform.isMacOS) {
                    session?.exitFullScreen();
                  }
                  context.pop();
                },
          child: _viewModel.hasNext ? const Text("Next") : const Text("Done"),
        ),
      ],
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
                "This routine has no exercises.",
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

  Widget _buildCard(BuildContext context, RoutinePlayEntry entry) {
    final theme = Theme.of(context);
    final session = PlaySession.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: session?.backButtonVisible ?? true,
        title: Text(_viewModel.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _openSheet,
              child: Text(
                "${_viewModel.position + 1} of ${_viewModel.length}",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          if (session != null) ...{
            const SingleActivator(LogicalKeyboardKey.escape):
                session.exitFullScreen,
            const SingleActivator(LogicalKeyboardKey.keyF):
                session.toggleFullScreen,
            const SingleActivator(LogicalKeyboardKey.f11):
                session.toggleFullScreen,
          },
        },
        child: FocusScope(
          autofocus: true,
          child: SafeArea(
            child: Stack(
              children: [
                ExerciseCard(
                  exercise: entry.exercise,
                  scoresUnavailable: entry.scoresUnavailable,
                ),
                if (session != null)
                  FullScreenButton(
                    visible: session.overlayVisible,
                    fullScreen: session.isFullScreen,
                    onPressed: session.toggleFullScreen,
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildToolbar(context, showScores: false),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final entry = _viewModel.currentEntry;
    if (entry == null) return _buildEmpty(context);
    final scoreId = _viewModel.currentScoreId;
    if (scoreId == null) return _buildCard(context, entry);
    return ScoreViewer(
      initialScoreId: scoreId,
      sequence: _viewModel,
      // only the toolbar moves on to the next exercise
      advanceOnOverflow: false,
      onSwipeUp: _openSheet,
      topOverlay: SequenceBubble(
        name: _viewModel.exerciseName,
        index: _viewModel.position,
        length: _viewModel.length,
        onTap: _openSheet,
      ),
      bottomBar: _buildToolbar(context, showScores: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlaySession(child: Builder(builder: _buildContent));
  }
}
