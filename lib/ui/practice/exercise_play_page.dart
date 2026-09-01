/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/practice/exercise_card.dart';
import 'package:sheetopia/ui/practice/exercise_play_viewmodel.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/score/chrome/full_screen_button.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';
import 'package:sheetopia/ui/score/chrome/play_toolbar.dart';
import 'package:sheetopia/ui/score/score_viewer.dart';

class ExercisePlayPage extends StatefulWidget {
  final String exerciseId;

  const ExercisePlayPage({super.key, required this.exerciseId});

  @override
  State<ExercisePlayPage> createState() => _ExercisePlayPageState();
}

class _ExercisePlayPageState extends State<ExercisePlayPage> {
  late final ExercisePlayViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExercisePlayViewModel(
      repo: context.read(),
      scoresRepo: context.read(),
      exerciseId: widget.exerciseId,
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

  Widget _buildCard(BuildContext context) {
    final exercise = _viewModel.exercise;
    final session = PlaySession.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: session?.backButtonVisible ?? true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (exercise != null)
              ExerciseCard(
                exercise: exercise,
                scoresUnavailable: _viewModel.hasScores,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlaySession(child: Builder(builder: _buildContent));
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    final scoreId = _viewModel.currentScoreId;
    if (scoreId == null) return _buildCard(context);
    return ScoreViewer(
      initialScoreId: scoreId,
      sequence: _viewModel,
      bottomBar: PlayToolbar(
        center: ExerciseScoreSelector(
          scores: _viewModel.scores,
          selectedIndex: _viewModel.position,
          onSelected: _viewModel.selectScore,
        ),
      ),
    );
  }
}
