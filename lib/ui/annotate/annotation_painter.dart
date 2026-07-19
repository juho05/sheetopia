/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';

// The outline is built in a fixed-size reference space and the canvas is scaled
// to the real size instead of feeding the zoomed size to perfect_freehand. Its
// sharp-corner threshold is `size / 128` compared against a unit-vector dot
// product (max 1.0), so a large `size` at high zoom flags every point as a
// corner and turns the stroke into a chain of caps. Keeping `size` fixed avoids
// that and makes rendering scale-invariant; the vector path stays crisp.
const double _refWidth = 1000.0;

Path _strokePath(Stroke stroke, Size size, {required bool isComplete}) {
  final points = stroke.points
      .map((p) => PointVector(p.x * size.width, p.y * size.height, p.pressure))
      .toList();

  final outline = getStroke(
    points,
    options: StrokeOptions(
      size: stroke.width * size.width,
      isComplete: isComplete,
      simulatePressure: false,
    ),
  );

  final path = Path();
  if (outline.isEmpty) return path;
  path.moveTo(outline.first.dx, outline.first.dy);
  for (var i = 0; i < outline.length - 1; i++) {
    final p0 = outline[i];
    final p1 = outline[i + 1];
    path.quadraticBezierTo(
      p0.dx,
      p0.dy,
      (p0.dx + p1.dx) / 2,
      (p0.dy + p1.dy) / 2,
    );
  }
  path.close();
  return path;
}

// Paints the committed strokes plus the eraser cursor. Repaints only when a
// stroke is committed/erased or the eraser cursor moves, not per live pen
// sample, so completed strokes are not re-tessellated while drawing.
class AnnotationPainter extends CustomPainter {
  final List<Stroke> strokes;
  final StrokePoint? eraserCursor;
  final double eraserWidth;

  AnnotationPainter({
    required this.strokes,
    this.eraserCursor,
    this.eraserWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (size.width > 0 && strokes.isNotEmpty) {
      final refSize = Size(_refWidth, _refWidth * (size.height / size.width));
      canvas.save();
      canvas.scale(size.width / _refWidth);
      for (final stroke in strokes) {
        if (stroke.points.isEmpty) continue;
        paint.color = Color(stroke.colorValue);
        canvas.drawPath(_strokePath(stroke, refSize, isComplete: true), paint);
      }
      canvas.restore();
    }
    if (eraserCursor != null) {
      _paintEraserCursor(canvas, size, eraserCursor!);
    }
  }

  void _paintEraserCursor(Canvas canvas, Size size, StrokePoint p) {
    final center = Offset(p.x * size.width, p.y * size.height);
    final radius = eraserWidth / 2 * size.width;
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
        oldDelegate.eraserCursor != eraserCursor ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}

// Paints only the in-progress pen stroke, on its own repaint boundary. Drawn as
// a constant-width stroked polyline (cheap, constant cost per sample) instead of
// the variable-width perfect_freehand fill; the committed stroke uses the fill.
class LiveStrokePainter extends CustomPainter {
  final AnnotateViewModel viewModel;
  final int pageIndex;

  LiveStrokePainter({required this.viewModel, required this.pageIndex})
    : super(repaint: viewModel.liveRepaint);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = viewModel.liveStrokeFor(pageIndex);
    if (stroke == null || stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..strokeWidth = stroke.width * size.width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final points = stroke.points;
    if (points.length == 1) {
      final p = points.first;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        paint.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()
      ..moveTo(points.first.x * size.width, points.first.y * size.height);
    for (final p in points.skip(1)) {
      path.lineTo(p.x * size.width, p.y * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LiveStrokePainter oldDelegate) => true;
}
