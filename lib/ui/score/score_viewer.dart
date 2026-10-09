/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_toolbar.dart';
import 'package:sheetopia/ui/common/overlay_icon_button.dart';
import 'package:sheetopia/ui/score/annotation_mode.dart';
import 'package:sheetopia/data/repositories/settings/page_turning.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';
import 'package:sheetopia/ui/score/chrome/full_screen_button.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';
import 'package:sheetopia/ui/score/pdf_view.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';
import 'package:sheetopia/ui/score/unsupported_file_view.dart';
import 'package:sheetopia/utils/full_screen.dart';

const _boundKeys = [
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.f11,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.pageUp,
  LogicalKeyboardKey.pageDown,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.backspace,
];

class ScoreViewer extends StatelessWidget {
  final String initialScoreId;
  final ScoreSequence? sequence;

  final Widget? topOverlay;
  final Widget? bottomBar;
  final void Function()? onSwipeUp;

  final bool advanceOnOverflow;

  const ScoreViewer({
    super.key,
    required this.initialScoreId,
    this.sequence,
    this.topOverlay,
    this.bottomBar,
    this.onSwipeUp,
    this.advanceOnOverflow = true,
  });

  @override
  Widget build(BuildContext context) {
    final viewer = _ScoreViewer(
      initialScoreId: initialScoreId,
      sequence: sequence,
      topOverlay: topOverlay,
      bottomBar: bottomBar,
      onSwipeUp: onSwipeUp,
      advanceOnOverflow: advanceOnOverflow,
    );
    if (PlaySession.isActive(context)) return viewer;
    return PlaySession(child: viewer);
  }
}

class _ScoreViewer extends StatefulWidget {
  final String initialScoreId;
  final ScoreSequence? sequence;

  final Widget? topOverlay;
  final Widget? bottomBar;
  final void Function()? onSwipeUp;

  final bool advanceOnOverflow;

  const _ScoreViewer({
    required this.initialScoreId,
    required this.sequence,
    required this.topOverlay,
    required this.bottomBar,
    required this.onSwipeUp,
    required this.advanceOnOverflow,
  });

  @override
  State<_ScoreViewer> createState() => _ScoreViewerState();
}

class _ScoreViewerState extends State<_ScoreViewer>
    with SingleTickerProviderStateMixin {
  late final ScoreViewModel _viewModel;
  late final PageTurningSettings _pageTurningSettings;
  late final Listenable _rebuildListenable;

  final Color _forwardHighlight = Colors.green;
  final Color _backwardHighlight = Colors.orange;

  late final AnimationController _pageTurnHighlightController;

  Animation<Color?>? _pageTurnHighlightAnimation;

  StreamSubscription? _pageChangeSub;

  late final AnnotationMode _annotation;

  @override
  void initState() {
    super.initState();
    _annotation = AnnotationMode(repo: context.read());
    _viewModel = ScoreViewModel(
      repo: context.read(),
      midiRepository: context.read(),
      scoreId: widget.initialScoreId,
      sequence: widget.sequence,
    );
    _pageTurningSettings = context.read<SettingsRepository>().pageTurning;
    _rebuildListenable = Listenable.merge([
      _viewModel,
      _pageTurningSettings,
      _annotation,
    ]);
    _viewModel.addListener(_exitAnnotationWithoutPdf);
    _pageTurnHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageChangeSub = _viewModel.pageChangedStream.listen(
      _triggerPageTurnHighlight,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final surfaceColor = Theme.of(context).colorScheme.surface;

    // dummy animation for beginning
    _pageTurnHighlightAnimation ??=
        ColorTween(begin: surfaceColor, end: surfaceColor).animate(
          CurvedAnimation(
            parent: _pageTurnHighlightController,
            curve: Curves.easeOut,
          ),
        );
  }

  @override
  void dispose() {
    _pageChangeSub?.cancel();
    _viewModel.dispose();
    _annotation.dispose();
    _pageTurnHighlightController.dispose();
    super.dispose();
  }

  void _exitAnnotationWithoutPdf() {
    if (_viewModel.fileType != FileType.pdf) _annotation.exit();
  }

  Widget _buildAnnotationChrome(AnnotateViewModel annotator) {
    return Positioned.fill(
      child: AnnotationToolbar(
        viewModel: annotator,
        bottomPadding: widget.bottomBar == null ? 16 : 4,
        atTop: _annotation.toolbarAtTop,
        slideIn: true,
        onPaste: _annotation.paste,
        onDone: _annotation.exit,
        pageMaxSidePx: () => _annotation.pageMaxSide,
      ),
    );
  }

  void _triggerPageTurnHighlight(bool forward) {
    if (!_pageTurningSettings.flashOnPageTurn) return;

    final targetColor = forward ? _forwardHighlight : _backwardHighlight;

    _pageTurnHighlightAnimation =
        ColorTween(
          begin: targetColor,
          end: Theme.of(context).colorScheme.surface,
        ).animate(
          CurvedAnimation(
            parent: _pageTurnHighlightController,
            curve: Curves.easeOut,
          ),
        );

    _pageTurnHighlightController.value = 0.3;
    _pageTurnHighlightController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final child = SafeArea(
      bottom: widget.bottomBar == null,
      child: ListenableBuilder(
        listenable: _rebuildListenable,
        builder: (context, _) {
          final session = PlaySession.of(context)!;
          final sequence = widget.sequence;
          final annotator = _annotation.viewModel;
          final annotating = annotator != null;
          return MouseRegion(
            cursor:
                !session.isFullScreen || session.overlayVisible || annotating
                ? SystemMouseCursors.basic
                : SystemMouseCursors.none,
            child: Shortcuts(
              shortcuts: {
                for (final key in _boundKeys)
                  SingleActivator(key): const DoNothingIntent(),
              },
              child: CallbackShortcuts(
                bindings: {
                  if (annotating) ...annotationShortcuts(annotator),
                  const SingleActivator(
                    LogicalKeyboardKey.escape,
                    includeRepeats: false,
                  ): !annotating
                      ? session.exitFullScreen
                      : annotator.hasSelection
                      ? annotator.clearSelection
                      : _annotation.exit,
                  const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    includeRepeats: false,
                  ): _annotation.toggle,
                  const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    includeRepeats: false,
                  ): session.toggleFullScreen,
                  const SingleActivator(
                    LogicalKeyboardKey.f11,
                    includeRepeats: false,
                  ): session.toggleFullScreen,
                  const SingleActivator(
                    LogicalKeyboardKey.arrowUp,
                    includeRepeats: false,
                  ): _viewModel.prevPage,
                  const SingleActivator(
                    LogicalKeyboardKey.arrowDown,
                    includeRepeats: false,
                  ): _viewModel.nextPage,
                  const SingleActivator(
                    LogicalKeyboardKey.arrowLeft,
                    includeRepeats: false,
                  ): _viewModel.prevPage,
                  const SingleActivator(
                    LogicalKeyboardKey.arrowRight,
                    includeRepeats: false,
                  ): _viewModel.nextPage,
                  const SingleActivator(
                    LogicalKeyboardKey.pageUp,
                    includeRepeats: false,
                  ): _viewModel.prevPage,
                  const SingleActivator(
                    LogicalKeyboardKey.pageDown,
                    includeRepeats: false,
                  ): _viewModel.nextPage,
                  const SingleActivator(
                    LogicalKeyboardKey.space,
                    includeRepeats: false,
                  ): _viewModel.nextPage,
                  const SingleActivator(
                    LogicalKeyboardKey.enter,
                    includeRepeats: false,
                  ): _viewModel.nextPage,
                  const SingleActivator(
                    LogicalKeyboardKey.backspace,
                    includeRepeats: false,
                  ): _viewModel.prevPage,
                },
                child: FocusScope(
                  autofocus: true,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            if (_viewModel.file == null)
                              const Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            if (_viewModel.file != null)
                              switch (_viewModel.fileType!) {
                                FileType.pdf => PdfView(
                                  file: _viewModel.file!,
                                  scoreId: _viewModel.scoreId,
                                  switchToken: _viewModel.switchToken,
                                  switchSettleCount:
                                      _viewModel.switchSettleCount,
                                  controller: _viewModel.fileView,
                                  annotation: _annotation,
                                  gradualPageTurns:
                                      _pageTurningSettings.gradualPageTurns,
                                  nextPath: sequence?.nextFile?.path,
                                  previousPath: sequence?.previousFile?.path,
                                  nextScoreId: widget.advanceOnOverflow
                                      ? sequence?.nextScoreId
                                      : null,
                                  neighborsSettled: _viewModel.sequenceSettled,
                                  onOverflowForward: widget.advanceOnOverflow
                                      ? sequence?.next
                                      : null,
                                  onOverflowBackward: widget.advanceOnOverflow
                                      ? sequence?.previous
                                      : null,
                                  canOverflowForward:
                                      widget.advanceOnOverflow &&
                                      (sequence?.hasNext ?? false),
                                  canOverflowBackward:
                                      widget.advanceOnOverflow &&
                                      (sequence?.hasPrevious ?? false),
                                  onPageTurned: _viewModel.onPageTurned,
                                  onSwipeUp: widget.onSwipeUp,
                                ),
                                _ => UnsupportedFileView(
                                  fileType: _viewModel.fileType!,
                                ),
                              },
                            FadingOverlay(
                              visible: session.backButtonVisible && !annotating,
                              child: OverlayIconButton(
                                icon: const BackButtonIcon(),
                                onPressed: () {
                                  AppFullScreen.setImmersive(false);
                                  context.pop();
                                },
                              ),
                            ),
                            if (widget.topOverlay != null)
                              FadingOverlay(
                                visible:
                                    !annotating &&
                                    ((supportsFullScreen &&
                                            session.overlayVisible) ||
                                        _viewModel.transientChromeVisible),
                                child: widget.topOverlay!,
                              ),
                            FullScreenButton(
                              visible: session.overlayVisible && !annotating,
                              fullScreen: session.isFullScreen,
                              onPressed: session.toggleFullScreen,
                            ),
                            if (annotating) _buildAnnotationChrome(annotator),
                          ],
                        ),
                      ),
                      // stays laid out so nothing shifts
                      if (widget.bottomBar != null)
                        Visibility(
                          visible: !annotating,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: widget.bottomBar!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _annotation.exit();
          AppFullScreen.setImmersive(false);
        }
      },
      child: StreamBuilder<bool>(
        stream: _viewModel.pageChangedStream,
        builder: (context, _) {
          return AnimatedBuilder(
            animation: _pageTurnHighlightAnimation!,
            child: child,
            builder: (context, child) {
              return Scaffold(
                backgroundColor: _pageTurnHighlightAnimation!.isAnimating
                    ? _pageTurnHighlightAnimation!.value
                    : null,
                body: child,
              );
            },
          );
        },
      ),
    );
  }
}
