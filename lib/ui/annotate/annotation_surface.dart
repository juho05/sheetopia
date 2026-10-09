/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_painter.dart';

class AnnotationSurface extends StatefulWidget {
  final AnnotateViewModel? viewModel;
  final int pageIndex;

  final List<Stroke> strokes;

  final AnnotateViewModel? Function(PointerDownEvent event)? onStylusDown;

  const AnnotationSurface({
    super.key,
    required this.viewModel,
    required this.pageIndex,
    this.strokes = const [],
    this.onStylusDown,
  });

  @override
  State<AnnotationSurface> createState() => _AnnotationSurfaceState();
}

class _AnnotationSurfaceState extends State<AnnotationSurface> {
  static const double _tapSlop = 8;

  Size _size = Size.zero;

  // The view model taking the stroke in progress. The widget only catches up
  // with one from onStylusDown on the next frame.
  AnnotateViewModel? _drawing;

  Offset? _tapOrigin;

  static const Duration _holdDelay = Duration(milliseconds: 1000);

  // In on-screen pixels, wide enough for the jitter of a resting stylus.
  static const double _holdSlop = 8;

  Timer? _holdTimer;
  Offset _holdOrigin = Offset.zero;

  void _armHold(Offset position) {
    _holdOrigin = position;
    _holdTimer?.cancel();
    _holdTimer = Timer(
      _holdDelay,
      () => _drawing?.snapToShape(pageWidth: _size.width),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  bool _isStylus(PointerDownEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  bool _shouldDraw(PointerDownEvent event) {
    final viewModel = widget.viewModel;
    if (viewModel == null) {
      return widget.onStylusDown != null && _isStylus(event);
    }
    if (_isStylus(event)) return true;
    if (event.kind == PointerDeviceKind.mouse) {
      return viewModel.drawMode && event.buttons == kPrimaryButton;
    }
    return viewModel.drawMode;
  }

  StrokePoint _normalize(Offset local) {
    final w = _size.width <= 0 ? 1.0 : _size.width;
    final h = _size.height <= 0 ? 1.0 : _size.height;
    return StrokePoint(
      x: (local.dx / w).clamp(0.0, 1.0),
      y: (local.dy / h).clamp(0.0, 1.0),
      pressure: 0.5, // disable pressure-sensitivity
    );
  }

  double get _aspect => _size.width <= 0 ? 1.0 : _size.height / _size.width;

  void _onStart(PointerDownEvent event) {
    var viewModel = widget.viewModel;
    if (viewModel == null) {
      viewModel = widget.onStylusDown?.call(event);
      _tapOrigin = event.position;
    }
    _drawing = viewModel;
    viewModel?.startStroke(
      widget.pageIndex,
      _normalize(event.localPosition),
      _aspect,
      isTouch: event.kind == PointerDeviceKind.touch,
    );
    _armHold(event.position);
  }

  void _onUpdate(PointerMoveEvent event) {
    final origin = _tapOrigin;
    if (origin != null && (event.position - origin).distance > _tapSlop) {
      _tapOrigin = null;
    }
    if ((event.position - _holdOrigin).distance > _holdSlop) {
      _armHold(event.position);
    }
    _drawing?.appendPoint(
      _normalize(event.localPosition),
      _aspect,
      pageWidth: _size.width,
    );
  }

  void _onEnd() {
    _holdTimer?.cancel();
    if (_tapOrigin != null) {
      _drawing?.cancelStroke();
    } else {
      _drawing?.endStroke();
    }
    _tapOrigin = null;
    _drawing = null;
  }

  // The inner RepaintBoundary is what makes a drag cheap: the Transform above
  // it only swaps a layer matrix, so the selected strokes and their marquee are
  // rasterized once and recomposited from then on.
  Widget _buildSelection(AnnotateViewModel viewModel) {
    final selection = viewModel.selectionFor(widget.pageIndex);
    if (selection == null) return const SizedBox.expand();
    return ValueListenableBuilder<Offset>(
      valueListenable: viewModel.dragOffset,
      builder: (context, offset, child) => Transform.translate(
        offset: Offset(offset.dx * _size.width, offset.dy * _size.height),
        child: child,
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: SelectionPainter(
            strokes: selection.strokes,
            polygon: selection.polygon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            _DrawGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<_DrawGestureRecognizer>(
                  () => _DrawGestureRecognizer(),
                  (recognizer) {
                    recognizer
                      ..shouldAllow = _shouldDraw
                      ..onDrawStart = _onStart
                      ..onDrawUpdate = _onUpdate
                      ..onDrawEnd = _onEnd;
                  },
                ),
          },
          child: viewModel == null
              ? CustomPaint(
                  size: Size.infinite,
                  painter: AnnotationPainter(strokes: widget.strokes),
                )
              : _buildLayers(viewModel),
        );
      },
    );
  }

  Widget _buildLayers(AnnotateViewModel viewModel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              final eraserCursor = viewModel.eraserCursorFor(widget.pageIndex);
              return CustomPaint(
                size: Size.infinite,
                painter: AnnotationPainter(
                  strokes: viewModel.strokesFor(widget.pageIndex),
                  hidden: viewModel.selectionStrokesFor(widget.pageIndex),
                  eraserCursor: eraserCursor,
                  // Only track width while it is actually drawn, so the
                  // width slider does not repaint every committed stroke.
                  eraserWidth: eraserCursor == null ? 0 : viewModel.width,
                ),
              );
            },
          ),
        ),
        // The marquee can reach past the strokes it encloses, so a drag
        // that keeps them on the page can still push it off one.
        ClipRect(
          child: RepaintBoundary(
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => _buildSelection(viewModel),
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: LassoPainter(
              viewModel: viewModel,
              pageIndex: widget.pageIndex,
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: LiveStrokePainter(
              viewModel: viewModel,
              pageIndex: widget.pageIndex,
            ),
          ),
        ),
      ],
    );
  }
}

// Claims only the pointers that should draw (stylus always; mouse/finger only
// in draw mode) and wins the gesture arena for them, so the PdfViewer keeps
// pan/zoom for every other pointer -- a stylus draws while a finger pans.
class _DrawGestureRecognizer extends OneSequenceGestureRecognizer {
  bool Function(PointerDownEvent event)? shouldAllow;
  void Function(PointerDownEvent event)? onDrawStart;
  void Function(PointerMoveEvent event)? onDrawUpdate;
  void Function()? onDrawEnd;

  int? _pointer;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      _pointer == null && (shouldAllow?.call(event) ?? false);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointer = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onDrawStart?.call(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      onDrawUpdate?.call(event);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      onDrawEnd?.call();
      stopTrackingPointer(event.pointer);
      _pointer = null;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_pointer == pointer) _pointer = null;
  }

  @override
  String get debugDescription => 'annotation_draw';
}
