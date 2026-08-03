/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
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

  final GlobalKey _stackKey = GlobalKey();

  PdfDocumentRefFile? _pdfRef;

  // Finger position (in _stackKey-local coords) while dragging the width slider;
  // null hides the floating stroke-width preview.
  Offset? _widthPreviewAt;

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

  void _showWidthPreview(Offset globalPosition) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() => _widthPreviewAt = box.globalToLocal(globalPosition));
  }

  void _hideWidthPreview() {
    if (_widthPreviewAt != null) setState(() => _widthPreviewAt = null);
  }

  double _currentPageMaxSidePx() {
    if (!_controller.isReady) return 0;
    final page = _controller.pageNumber;
    final pages = _controller.layout.pageLayouts;
    if (page == null || page < 1 || page > pages.length) return 0;
    final rect = pages[page - 1];
    return max(rect.width, rect.height) * _controller.value.getMaxScaleOnAxis();
  }

  @override
  Widget build(BuildContext context) {
    final bool isApple = Platform.isMacOS || Platform.isIOS;
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _viewModel.saveAll();
        },
        child: CallbackShortcuts(
          bindings: {
            SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: !isApple,
              meta: isApple,
            ): _viewModel.undo,
            SingleActivator(
              LogicalKeyboardKey.keyY,
              control: !isApple,
              meta: isApple,
            ): _viewModel.redo,
            SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: !isApple,
              meta: isApple,
              shift: true,
            ): _viewModel.redo,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: SafeArea(
                child: Stack(
                  key: _stackKey,
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
                        child: _Toolbar(
                          viewModel: _viewModel,
                          onWidthPreview: _showWidthPreview,
                          onWidthPreviewEnd: _hideWidthPreview,
                        ),
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
                          onPressed: context.pop,
                        ),
                      ),
                    ),
                    if (_widthPreviewAt != null)
                      _WidthPreview(
                        viewModel: _viewModel,
                        at: _widthPreviewAt!,
                        pageMaxSidePx: _currentPageMaxSidePx(),
                      ),
                  ],
                ),
              ),
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

// A stationary two-/three-finger tap: undo/redo. It never competes in the
// gesture arena, it only watches the touch pointers, so pinch-to-zoom, panning
// and drawing keep working exactly as before. The tap is discarded as soon as
// any finger travels beyond the pan slop (that is where a pinch/pan starts) or
// the fingers stay down longer than _tapTimeout.
class _MultiFingerTapRecognizer extends OneSequenceGestureRecognizer {
  static const Duration _tapTimeout = Duration(milliseconds: 400);

  void Function(int fingers)? onMultiFingerTap;
  VoidCallback? onSecondFingerDown;

  final Map<int, Offset> _origins = {};
  int _maxFingers = 0;
  bool _failed = false;
  Timer? _timeout;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      event.kind == PointerDeviceKind.touch;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.rejected);
    if (_origins.isEmpty) {
      _failed = false;
      _maxFingers = 0;
      _timeout = Timer(_tapTimeout, () => _failed = true);
    }
    _origins[event.pointer] = event.position;
    _maxFingers = max(_maxFingers, _origins.length);
    if (_origins.length == 2 && !_failed) onSecondFingerDown?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    final origin = _origins[event.pointer];
    if (origin == null) return;
    if (event is PointerMoveEvent) {
      if ((event.position - origin).distance >
          computePanSlop(event.kind, gestureSettings)) {
        _failed = true;
      }
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (event is PointerCancelEvent) _failed = true;
      _origins.remove(event.pointer);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _timeout?.cancel();
    _timeout = null;
    _origins.clear();
    final fingers = _maxFingers;
    final failed = _failed;
    _maxFingers = 0;
    _failed = false;
    if (!failed && fingers >= 2) onMultiFingerTap?.call(fingers);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  String get debugDescription => 'annotation_multi_finger_tap';
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
  late final AnimationController _fling;
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
  void initState() {
    super.initState();
    _fling = AnimationController.unbounded(vsync: this)
      ..addListener(_onFlingTick);
  }

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

  void _onMultiFingerTap(int fingers) {
    final viewModel = widget.viewModel;
    if (fingers == 2 && viewModel.canUndo) {
      viewModel.undo();
    } else if (fingers == 3 && viewModel.canRedo) {
      viewModel.redo();
    } else {
      return;
    }
    HapticFeedback.lightImpact();
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
              _MultiFingerTapRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _MultiFingerTapRecognizer
                  >(() => _MultiFingerTapRecognizer(), (recognizer) {
                    recognizer
                      // In draw mode the first finger already started a
                      // stroke. A second finger means the user is gesturing.
                      ..onSecondFingerDown = widget.viewModel.cancelTouchStroke
                      ..onMultiFingerTap = _onMultiFingerTap;
                  }),
            },
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

// A bare circle at the true on-screen stroke size, floating just above the
// finger while the width slider is dragged, horizontally centered on it.
class _WidthPreview extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final Offset at;
  final double pageMaxSidePx;

  static const double _gap = 36;

  const _WidthPreview({
    required this.viewModel,
    required this.at,
    required this.pageMaxSidePx,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final d = max(viewModel.width * pageMaxSidePx, 2.0);
        final fill = viewModel.eraser
            ? Colors.black.withValues(alpha: 0.1)
            : Color.alphaBlend(Color(viewModel.colorValue), Colors.white);
        return Positioned(
          left: at.dx - d / 2,
          top: at.dy - _gap - d,
          child: IgnorePointer(
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final void Function(Offset globalPosition) onWidthPreview;
  final VoidCallback onWidthPreviewEnd;

  const _Toolbar({
    required this.viewModel,
    required this.onWidthPreview,
    required this.onWidthPreviewEnd,
  });

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  Row(
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
                              border: viewModel.eraser
                                  ? Border.all(
                                      color: theme.colorScheme.primary,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: const Icon(Symbols.ink_eraser, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 110,
                    height: 40,
                    child: Listener(
                      onPointerDown: (e) => onWidthPreview(e.position),
                      onPointerMove: (e) => onWidthPreview(e.position),
                      onPointerUp: (_) => onWidthPreviewEnd(),
                      onPointerCancel: (_) => onWidthPreviewEnd(),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: viewModel.widthFraction,
                          onChanged: viewModel.setWidthFraction,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
