/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';

class _CachedPath {
  final Size size;
  final Path path;

  const _CachedPath(this.size, this.path);
}

final _pathCache = Expando<_CachedPath>('annotationStrokePath');

Path _strokePath(Stroke stroke, Size size) {
  final cached = _pathCache[stroke];
  if (cached != null && cached.size == size) return cached.path;
  final path = _buildStrokePath(stroke, size);
  _pathCache[stroke] = _CachedPath(size, path);
  return path;
}

Rect? _strokeRect(Stroke stroke, Size size) {
  if (stroke.points.isEmpty) return null;
  final b = stroke.bounds;
  return Rect.fromLTRB(
    b.minX * size.width,
    b.minY * size.height,
    b.maxX * size.width,
    b.maxY * size.height,
  ).inflate(stroke.width / 2 * max(size.width, size.height));
}

Path _buildStrokePath(Stroke stroke, Size size) {
  final outline = stroke.outline;
  final path = Path();
  if (outline.length < 4) return path;
  path.moveTo(outline[0] * size.width, outline[1] * size.height);
  for (var i = 0; i + 3 < outline.length; i += 2) {
    final x0 = outline[i] * size.width;
    final y0 = outline[i + 1] * size.height;
    final x1 = outline[i + 2] * size.width;
    final y1 = outline[i + 3] * size.height;
    path.quadraticBezierTo(x0, y0, (x0 + x1) / 2, (y0 + y1) / 2);
  }
  path.close();
  return path;
}

const double _dash = 10;
const double _gap = 6;
const double _period = _dash + _gap;
const Color _marqueeColor = Color(0xFF1976D2);

Paint _marqueePaint() => Paint()
  ..color = _marqueeColor
  ..strokeWidth = 2.5
  ..style = PaintingStyle.stroke
  ..isAntiAlias = true;

// A dashed polyline baked into one Path, in on-screen pixels. Kept across
// frames: a lasso being drawn only pays for the segments it just grew by, and
// a selection being dragged pays nothing at all, since the marquee moves with
// the layer instead of being re-emitted.
class _DashedPath {
  final Size size;
  final Path path = Path();

  // Points already walked, the running arc-length phase so dashes carry over
  // corners, and the pen position the next segment starts from.
  int _walked = 0;
  double _phase = 0;
  double _x = 0;
  double _y = 0;
  bool _done = false;

  _DashedPath(this.size);

  void extend(List<double> points, {required bool close}) {
    if (_done) return;
    final n = points.length ~/ 2;
    if (n < 2) return;
    if (_walked == 0) {
      _x = points[0] * size.width;
      _y = points[1] * size.height;
      _walked = 1;
    }
    for (var i = _walked; i < n; i++) {
      _lineTo(points[i * 2] * size.width, points[i * 2 + 1] * size.height);
    }
    _walked = n;
    if (close) {
      _lineTo(points[0] * size.width, points[1] * size.height);
      _done = true;
    }
  }

  void _lineTo(double bx, double by) {
    final dx = bx - _x;
    final dy = by - _y;
    final length = sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final ux = dx / length;
    final uy = dy / length;
    var t = 0.0;
    while (t < length) {
      final span = _phase < _dash
          ? min(_dash - _phase, length - t)
          : min(_period - _phase, length - t);
      if (_phase < _dash) {
        path
          ..moveTo(_x + ux * t, _y + uy * t)
          ..lineTo(_x + ux * (t + span), _y + uy * (t + span));
      }
      t += span;
      _phase = (_phase + span) % _period;
    }
    _x = bx;
    _y = by;
  }
}

final _dashCache = Expando<_DashedPath>('annotationDashedPolyline');

// points must not be mutated except by appending, which is what both callers
// do: a selection polygon is final, an in-progress lasso only grows.
Path _dashedPath(List<double> points, Size size, {required bool close}) {
  var cached = _dashCache[points];
  if (cached == null || cached.size != size) {
    cached = _DashedPath(size);
    _dashCache[points] = cached;
  }
  cached.extend(points, close: close);
  return cached.path;
}

// Paints the committed strokes plus the eraser cursor. Repaints only when a
// stroke is committed/erased or the eraser cursor moves, not per live pen
// sample, so completed strokes are not re-tessellated while drawing.
class AnnotationPainter extends CustomPainter {
  final List<Stroke> strokes;

  // Selected strokes, drawn by SelectionPainter on its own draggable layer.
  final Set<Stroke>? hidden;
  final StrokePoint? eraserCursor;
  final double eraserWidth;

  AnnotationPainter({
    required this.strokes,
    this.hidden,
    this.eraserCursor,
    this.eraserWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (size.width > 0 && strokes.isNotEmpty) {
      final clip = canvas.getLocalClipBounds();
      final hidden = this.hidden;
      for (final stroke in strokes) {
        if (stroke.outline.isEmpty) continue;
        if (hidden != null && hidden.contains(stroke)) continue;
        final rect = _strokeRect(stroke, size);
        if (rect != null && !rect.overlaps(clip)) continue;
        paint.color = Color(stroke.colorValue);
        canvas.drawPath(_strokePath(stroke, size), paint);
      }
    }
    if (eraserCursor != null) {
      _paintEraserCursor(canvas, size, eraserCursor!);
    }
  }

  void _paintEraserCursor(Canvas canvas, Size size, StrokePoint p) {
    final center = Offset(p.x * size.width, p.y * size.height);
    final radius = eraserWidth / 2 * max(size.width, size.height);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        !identical(oldDelegate.hidden, hidden) ||
        oldDelegate.eraserCursor != eraserCursor ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}

// Paints the selected strokes and the dotted marquee around them, both at rest:
// the drag offset is applied by a Transform above this painter's
// RepaintBoundary, so dragging recomposites a cached layer and never repaints.
//
// The page overlay is laid out in on-screen pixels (pdfrx bakes the zoom into
// the overlay rect), so the dashes are sized in plain logical pixels and stay
// constant as the user zooms, like the rest of the UI chrome.
class SelectionPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<double> polygon;

  const SelectionPainter({required this.strokes, required this.polygon});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final stroke in strokes) {
      if (stroke.outline.isEmpty) continue;
      paint.color = Color(stroke.colorValue);
      canvas.drawPath(_strokePath(stroke, size), paint);
    }
    canvas.drawPath(
      _dashedPath(polygon, size, close: true),
      _marqueePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) =>
      !identical(oldDelegate.strokes, strokes) ||
      !identical(oldDelegate.polygon, polygon);
}

// Paints the open marquee of the lasso being drawn, on its own repaint channel
// so pen samples do not dirty it.
class LassoPainter extends CustomPainter {
  final AnnotateViewModel viewModel;
  final int pageIndex;

  LassoPainter({required this.viewModel, required this.pageIndex})
    : super(repaint: viewModel.lassoRepaintFor(pageIndex));

  @override
  void paint(Canvas canvas, Size size) {
    final points = viewModel.lassoPointsFor(pageIndex);
    if (points == null || size.width <= 0) return;
    canvas.drawPath(
      _dashedPath(points, size, close: false),
      _marqueePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant LassoPainter oldDelegate) => true;
}

// Paints only the in-progress pen stroke, on its own repaint boundary. Drawn as
// a constant-width stroked polyline (cheap, constant cost per sample) instead of
// the variable-width perfect_freehand fill; the committed stroke uses the fill.
class LiveStrokePainter extends CustomPainter {
  final AnnotateViewModel viewModel;
  final int pageIndex;

  LiveStrokePainter({required this.viewModel, required this.pageIndex})
    : super(repaint: viewModel.liveRepaintFor(pageIndex));

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = viewModel.liveStrokeFor(pageIndex);
    if (stroke == null || size.width <= 0) return;

    final color = Color(stroke.colorValue);
    final strokeWidth = stroke.width * max(1.0, stroke.aspect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.save();
    canvas.scale(size.width);
    if (stroke.isDot) {
      canvas.drawCircle(
        stroke.lastKept,
        strokeWidth / 2,
        Paint()
          ..color = color
          ..isAntiAlias = true,
      );
    }
    canvas.drawPath(stroke.path, paint);
    // The round cap extends exactly as far as the decimation threshold, so it
    // already covers the gap to the nib. Only opaque strokes get the extra
    // segment; on a translucent one its overlap would show as a darker dot.
    if (color.a == 1.0 && stroke.tip != stroke.lastKept) {
      canvas.drawLine(stroke.lastKept, stroke.tip, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LiveStrokePainter oldDelegate) => true;
}
