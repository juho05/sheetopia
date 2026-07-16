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

class AnnotationPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? liveStroke;
  final StrokePoint? eraserCursor;
  final double eraserWidth;

  AnnotationPainter({
    required this.strokes,
    this.liveStroke,
    this.eraserCursor,
    this.eraserWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, size, stroke, isComplete: true);
    }
    if (liveStroke != null) {
      _paintStroke(canvas, size, liveStroke!, isComplete: false);
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

  void _paintStroke(
    Canvas canvas,
    Size size,
    Stroke stroke, {
    required bool isComplete,
  }) {
    if (stroke.points.isEmpty) return;

    final points = stroke.points
        .map(
          (p) => PointVector(p.x * size.width, p.y * size.height, p.pressure),
        )
        .toList();

    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: stroke.width * size.width,
        isComplete: isComplete,
        simulatePressure: false,
      ),
    );

    if (outline.isEmpty) return;

    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (final point in outline.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.liveStroke != liveStroke ||
        oldDelegate.strokes.length != strokes.length ||
        oldDelegate.eraserCursor != eraserCursor ||
        oldDelegate.eraserWidth != eraserWidth;
  }
}
