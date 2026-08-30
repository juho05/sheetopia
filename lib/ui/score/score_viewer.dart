/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/appearance.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';
import 'package:sheetopia/ui/score/pdf_view.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ScoreViewer extends StatefulWidget {
  final String initialScoreId;
  final ScoreSequence? sequence;

  final Widget? topOverlay;
  final Widget? bottomBar;
  final void Function()? onSwipeUp;

  const ScoreViewer({
    super.key,
    required this.initialScoreId,
    this.sequence,
    this.topOverlay,
    this.bottomBar,
    this.onSwipeUp,
  });

  @override
  State<ScoreViewer> createState() => _ScoreViewerState();
}

class _ScoreViewerState extends State<ScoreViewer>
    with SingleTickerProviderStateMixin {
  late final ScoreViewModel _viewModel;
  late final AppearanceSettings _appearanceSettings;

  final Color _forwardHighlight = Colors.green;
  final Color _backwardHighlight = Colors.orange;

  late final AnimationController _pageTurnHighlightController;

  Animation<Color?>? _pageTurnHighlightAnimation;

  StreamSubscription? _pageChangeSub;

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    _viewModel = ScoreViewModel(
      repo: context.read(),
      midiRepository: context.read(),
      scoreId: widget.initialScoreId,
      sequence: widget.sequence,
    );
    _appearanceSettings = context.read<SettingsRepository>().appearanceSettings;
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
    WakelockPlus.disable();
    if (FullScreen.isFullScreen && !Platform.isMacOS) {
      FullScreen.setFullScreen(false);
    }
    _pageChangeSub?.cancel();
    _viewModel.dispose();
    _pageTurnHighlightController.dispose();
    super.dispose();
  }

  void _triggerPageTurnHighlight(bool forward) {
    if (!_appearanceSettings.flashOnPageTurn) return;

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
        listenable: _viewModel,
        builder: (context, _) {
          final backButtonVisible =
              !_viewModel.isFullScreen ||
              (Platform.isMacOS && _viewModel.overlayVisible);
          final sequence = widget.sequence;
          return MouseRegion(
            cursor: !_viewModel.isFullScreen || _viewModel.overlayVisible
                ? SystemMouseCursors.basic
                : SystemMouseCursors.none,
            child: Listener(
              onPointerHover: (event) => _viewModel.showOverlay(),
              onPointerMove: (event) => _viewModel.showOverlay(),
              onPointerDown: (event) => _viewModel.showOverlay(),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      _viewModel.exitFullScreen,
                  const SingleActivator(LogicalKeyboardKey.keyF):
                      _viewModel.toggleFullScreen,
                  const SingleActivator(LogicalKeyboardKey.f11):
                      _viewModel.toggleFullScreen,
                  const SingleActivator(LogicalKeyboardKey.arrowUp):
                      _viewModel.prevPage,
                  const SingleActivator(LogicalKeyboardKey.arrowDown):
                      _viewModel.nextPage,
                  const SingleActivator(LogicalKeyboardKey.arrowLeft):
                      _viewModel.prevPage,
                  const SingleActivator(LogicalKeyboardKey.arrowRight):
                      _viewModel.nextPage,
                  const SingleActivator(LogicalKeyboardKey.pageUp):
                      _viewModel.prevPage,
                  const SingleActivator(LogicalKeyboardKey.pageDown):
                      _viewModel.nextPage,
                  const SingleActivator(LogicalKeyboardKey.space):
                      _viewModel.nextPage,
                  const SingleActivator(LogicalKeyboardKey.enter):
                      _viewModel.nextPage,
                  const SingleActivator(LogicalKeyboardKey.backspace):
                      _viewModel.prevPage,
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
                                  nextPath: sequence?.nextFile?.path,
                                  previousPath: sequence?.previousFile?.path,
                                  onOverflowForward: sequence?.next,
                                  onOverflowBackward: sequence?.previous,
                                  onPageTurned: _viewModel.onPageTurned,
                                  onSwipeUp: widget.onSwipeUp,
                                ),
                              },
                            FadingOverlay(
                              visible: backButtonVisible,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: SizedBox.square(
                                  dimension: 32,
                                  child: IconButton.filled(
                                    color: Colors.white,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Colors.black.withAlpha(100),
                                      ),
                                    ),
                                    icon: const BackButtonIcon(),
                                    iconSize: 20,
                                    padding: const EdgeInsets.all(0),
                                    onPressed: () {
                                      context.pop();
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (widget.topOverlay != null)
                              FadingOverlay(
                                visible: _viewModel.chromeVisible,
                                child: widget.topOverlay!,
                              ),
                            if (Platform.isWindows ||
                                Platform.isMacOS ||
                                Platform.isLinux)
                              FadingOverlay(
                                visible: _viewModel.overlayVisible,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: IconButton.filled(
                                      onPressed: () {
                                        _viewModel.toggleFullScreen();
                                      },
                                      color: Colors.white,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                              Colors.black.withAlpha(100),
                                            ),
                                      ),
                                      iconSize: 26,
                                      padding: const EdgeInsets.all(10),
                                      icon: _viewModel.isFullScreen
                                          ? const Icon(Icons.fullscreen_exit)
                                          : const Icon(Icons.fullscreen),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.bottomBar != null) widget.bottomBar!,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    return StreamBuilder<bool>(
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
    );
  }
}
