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
      final clip = canvas.getLocalClipBounds();
      for (final stroke in strokes) {
        if (stroke.outline.isEmpty) continue;
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
