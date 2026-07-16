/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_surface.dart';
import 'package:sheetopia/ui/common/confirmation.dart';

class AnnotatePage extends StatefulWidget {
  final String scoreId;

  const AnnotatePage({super.key, required this.scoreId});

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  late final AnnotateViewModel _viewModel;

  final PdfViewerController _controller = PdfViewerController();

  PdfDocumentRefFile? _pdfRef;

  @override
  void initState() {
    super.initState();
    _viewModel = AnnotateViewModel(
      repo: context.read(),
      scoreId: widget.scoreId,
    );
    _loadFile();
  }

  Future<void> _loadFile() async {
    final score = await context.read<ScoresRepository>().getScore(
      widget.scoreId,
    );
    if (!mounted) return;
    final file = score?.file;
    setState(() {
      _pdfRef = file == null
          ? null
          : PdfDocumentRefFile(file.path, autoDispose: true);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    await _viewModel.saveAll();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _saveAndClose();
        },
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                if (_pdfRef == null)
                  const Center(child: CircularProgressIndicator.adaptive())
                else
                  PdfViewer(
                    _pdfRef!,
                    controller: _controller,
                    params: PdfViewerParams(
                      interactionDelegateProvider:
                          const PdfViewerScrollInteractionDelegateProviderPhysics(),
                      scrollPhysics: const ClampingScrollPhysics(),
                      // All pan/zoom/wheel is driven by _PanZoomOverlay so a
                      // stylus can keep drawing while a finger navigates. pdfrx's
                      // own handling stays off; leaving the wheel enabled would
                      // double-handle it (pdfrx scrolls a ctrl+wheel while we
                      // zoom it, since it handles pointer signals directly).
                      panEnabled: false,
                      scaleEnabled: false,
                      textSelectionParams: const PdfTextSelectionParams(
                        enabled: false,
                      ),
                      pageOverlaysBuilder: (context, pageRect, page) => [
                        AnnotationSurface(
                          viewModel: _viewModel,
                          pageIndex: page.pageNumber - 1,
                        ),
                      ],
                    ),
                  ),
                if (_pdfRef != null)
                  Positioned.fill(
                    child: _PanZoomOverlay(
                      controller: _controller,
                      viewModel: _viewModel,
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _Toolbar(viewModel: _viewModel),
                  ),
                ),
                Padding(
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
                      onPressed: _saveAndClose,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// A ScaleGestureRecognizer that only navigates the pointers it should: a stylus
// never navigates (it always draws), a trackpad always navigates (both modes),
// and touch/mouse navigate only in pan mode (in draw mode they draw).
class _NavScaleGestureRecognizer extends ScaleGestureRecognizer {
  final bool Function() isDrawMode;

  _NavScaleGestureRecognizer({required this.isDrawMode});

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return false;
      default:
        return !isDrawMode() && super.isPointerAllowed(event);
    }
  }
}

// Drives the PdfViewer's pan/zoom directly (pdfrx's own pan/scale are disabled)
// so a stylus keeps drawing on the AnnotationSurface below while everything else
// navigates. Trackpad gestures and ctrl+wheel zoom navigate in both modes; a
// finger/mouse drag follows the mode (draws in draw mode, pans in pan mode).
class _PanZoomOverlay extends StatefulWidget {
  final PdfViewerController controller;
  final AnnotateViewModel viewModel;

  const _PanZoomOverlay({required this.controller, required this.viewModel});

  @override
  State<_PanZoomOverlay> createState() => _PanZoomOverlayState();
}

class _PanZoomOverlayState extends State<_PanZoomOverlay>
    with SingleTickerProviderStateMixin {
  Offset? _referenceFocalScene;
  double _startScale = 1.0;
  PointerDeviceKind? _lastDownKind;

  // Ballistic pan/fling driven by the same simulation Android scroll views use.
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onFlingTick);
  ClampingScrollSimulation? _simX;
  ClampingScrollSimulation? _simY;
  double _lastFlingX = 0;
  double _lastFlingY = 0;
  double _flingScale = 1;

  // A trackpad's ScaleEndDetails velocity is unreliable (its pan arrives as
  // focal deltas), so we track pan velocity ourselves for the trackpad fling.
  final Stopwatch _panClock = Stopwatch();
  VelocityTracker? _panVelocity;
  Offset _panAccum = Offset.zero;

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  Offset _toScene(Offset viewportPoint) => MatrixUtils.transformPoint(
    Matrix4.inverted(widget.controller.value),
    viewportPoint,
  );

  void _onScaleStart(ScaleStartDetails details) {
    _fling.stop();
    if (!widget.controller.isReady) return;
    _startScale = widget.controller.value.getMaxScaleOnAxis();
    _referenceFocalScene = _toScene(details.localFocalPoint);
    _panAccum = Offset.zero;
    _panClock
      ..reset()
      ..start();
    _panVelocity = VelocityTracker.withKind(PointerDeviceKind.trackpad)
      ..addPosition(_panClock.elapsed, _panAccum);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_referenceFocalScene == null || !widget.controller.isReady) return;
    _panAccum += details.focalPointDelta;
    _panVelocity?.addPosition(_panClock.elapsed, _panAccum);
    if (details.scale != 1.0) {
      final currentScale = widget.controller.value.getMaxScaleOnAxis();
      final scaleChange = (_startScale * details.scale) / currentScale;
      widget.controller.value = widget.controller.value.clone()
        ..scaleByDouble(scaleChange, scaleChange, scaleChange, 1);
    }
    final focalScene = _toScene(details.localFocalPoint);
    final delta = focalScene - _referenceFocalScene!;
    widget.controller.value = widget.controller.value.clone()
      ..translateByDouble(delta.dx, delta.dy, 0, 1);
    _referenceFocalScene = _toScene(details.localFocalPoint);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _referenceFocalScene = null;
    if (!widget.controller.isReady) return;
    // Fling for a finger or a trackpad; a mouse drag does not fling.
    final isTrackpad = _lastDownKind == PointerDeviceKind.trackpad;
    if (_lastDownKind != PointerDeviceKind.touch && !isTrackpad) return;
    // A trackpad's ScaleEndDetails velocity is unreliable, so use our tracker.
    var velocity = isTrackpad
        ? (_panVelocity?.getVelocity().pixelsPerSecond ?? Offset.zero)
        : details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    if (speed < kMinFlingVelocity) return;
    if (speed > kMaxFlingVelocity) {
      velocity = velocity * (kMaxFlingVelocity / speed);
    }
    _simX = velocity.dx.abs() >= 1
        ? ClampingScrollSimulation(position: 0, velocity: velocity.dx)
        : null;
    _simY = velocity.dy.abs() >= 1
        ? ClampingScrollSimulation(position: 0, velocity: velocity.dy)
        : null;
    _lastFlingX = 0;
    _lastFlingY = 0;
    _flingScale = widget.controller.value.getMaxScaleOnAxis();
    _fling
      ..duration = const Duration(minutes: 1)
      ..forward(from: 0);
  }

  void _onFlingTick() {
    if (!widget.controller.isReady) return;
    final t =
        (_fling.lastElapsedDuration ?? Duration.zero).inMicroseconds /
        Duration.microsecondsPerSecond;
    var done = true;
    double dx = 0;
    double dy = 0;
    if (_simX != null) {
      final x = _simX!.x(t);
      dx = (x - _lastFlingX) / _flingScale;
      _lastFlingX = x;
      done = done && _simX!.isDone(t);
    }
    if (_simY != null) {
      final y = _simY!.x(t);
      dy = (y - _lastFlingY) / _flingScale;
      _lastFlingY = y;
      done = done && _simY!.isDone(t);
    }
    if (dx != 0 || dy != 0) {
      widget.controller.value = widget.controller.value.clone()
        ..translateByDouble(dx, dy, 0, 1);
    }
    if (done) _fling.stop();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.controller.isReady || event is! PointerScrollEvent) return;
    if (event.scrollDelta == Offset.zero) return;
    _fling.stop();
    final value = widget.controller.value;
    if (HardwareKeyboard.instance.isControlPressed) {
      final scaleChange = exp(-event.scrollDelta.dy * 0.002);
      final before = _toScene(event.localPosition);
      widget.controller.value = value.clone()
        ..scaleByDouble(scaleChange, scaleChange, scaleChange, 1);
      final after = _toScene(event.localPosition);
      widget.controller.value = widget.controller.value.clone()
        ..translateByDouble(after.dx - before.dx, after.dy - before.dy, 0, 1);
      return;
    }
    final scale = value.getMaxScaleOnAxis();
    widget.controller.value = value.clone()
      ..translateByDouble(
        -event.scrollDelta.dx / scale,
        -event.scrollDelta.dy / scale,
        0,
        1,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) => _lastDownKind = event.kind,
          onPointerPanZoomStart: (event) => _lastDownKind = event.kind,
          onPointerSignal: _onPointerSignal,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              _NavScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _NavScaleGestureRecognizer
                  >(
                    () => _NavScaleGestureRecognizer(
                      isDrawMode: () => widget.viewModel.drawMode,
                    ),
                    (recognizer) {
                      recognizer
                        ..onStart = _onScaleStart
                        ..onUpdate = _onScaleUpdate
                        ..onEnd = _onScaleEnd;
                    },
                  ),
            },
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AnnotateViewModel viewModel;

  const _Toolbar({required this.viewModel});

  Future<void> _clear(BuildContext context) async {
    final confirmed = await ConfirmationDialog.showYesNo(
      context,
      title: "Clear all annotations?",
      message: "This removes every stroke on all pages.",
    );
    if (confirmed == true) viewModel.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(MediaQuery.of(context).size.width - 32, 560),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: viewModel.drawMode ? "Draw" : "Move",
                      isSelected: viewModel.drawMode,
                      onPressed: viewModel.toggleDrawMode,
                      icon: Icon(
                        viewModel.drawMode ? Symbols.stylus : Icons.back_hand,
                      ),
                    ),
                    const SizedBox(width: 4),
                    for (final color in AnnotateViewModel.palette)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => viewModel.setColor(color),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.alphaBlend(
                                Color(color),
                                Colors.white,
                              ),
                              border: Border.all(
                                color:
                                    !viewModel.eraser &&
                                        viewModel.colorValue == color
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width:
                                    !viewModel.eraser &&
                                        viewModel.colorValue == color
                                    ? 3
                                    : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: viewModel.setEraser,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: viewModel.eraser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: viewModel.eraser ? 3 : 1,
                            ),
                          ),
                          child: Icon(
                            Symbols.ink_eraser,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 40,
                      child: Slider(
                        min: AnnotateViewModel.minWidth,
                        max: AnnotateViewModel.maxWidth,
                        value: viewModel.width.clamp(
                          AnnotateViewModel.minWidth,
                          AnnotateViewModel.maxWidth,
                        ),
                        onChanged: viewModel.setWidth,
                      ),
                    ),
                    IconButton(
                      tooltip: "Undo",
                      icon: const Icon(Icons.undo),
                      onPressed: viewModel.canUndo ? viewModel.undo : null,
                    ),
                    IconButton(
                      tooltip: "Redo",
                      icon: const Icon(Icons.redo),
                      onPressed: viewModel.canRedo ? viewModel.redo : null,
                    ),
                    IconButton(
                      tooltip: "Clear all",
                      icon: const Icon(Icons.delete_outline),
                      onPressed: viewModel.hasAnnotations
                          ? () => _clear(context)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
