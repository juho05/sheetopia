/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_painter.dart';

class AnnotationSurface extends StatefulWidget {
  final AnnotateViewModel viewModel;
  final int pageIndex;

  const AnnotationSurface({
    super.key,
    required this.viewModel,
    required this.pageIndex,
  });

  @override
  State<AnnotationSurface> createState() => _AnnotationSurfaceState();
}

class _AnnotationSurfaceState extends State<AnnotationSurface> {
  Size _size = Size.zero;

  bool _shouldDraw(PointerDownEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.mouse:
        return widget.viewModel.drawMode && event.buttons == kPrimaryButton;
      default:
        return widget.viewModel.drawMode;
    }
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
    widget.viewModel.startStroke(
      widget.pageIndex,
      _normalize(event.localPosition),
      _aspect,
    );
  }

  void _onUpdate(PointerMoveEvent event) {
    widget.viewModel.appendPoint(
      _normalize(event.localPosition),
      _aspect,
    );
  }

  void _onEnd() {
    widget.viewModel.endStroke();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) {
                    final eraserCursor = widget.viewModel.eraserCursorFor(
                      widget.pageIndex,
                    );
                    return CustomPaint(
                      size: Size.infinite,
                      painter: AnnotationPainter(
                        strokes: widget.viewModel.strokesFor(widget.pageIndex),
                        eraserCursor: eraserCursor,
                        // Only track width while it is actually drawn, so the
                        // width slider does not repaint every committed stroke.
                        eraserWidth: eraserCursor == null
                            ? 0
                            : widget.viewModel.width,
                      ),
                    );
                  },
                ),
              ),
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: LiveStrokePainter(
                    viewModel: widget.viewModel,
                    pageIndex: widget.pageIndex,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
