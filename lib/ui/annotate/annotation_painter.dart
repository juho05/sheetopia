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

Path _strokePath(Stroke stroke, Size size) {
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
      for (final stroke in strokes) {
        if (stroke.outline.isEmpty) continue;
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
      ..strokeWidth = stroke.width * max(size.width, size.height)
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
