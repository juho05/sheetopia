/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:one_dollar_unistroke_recognizer/one_dollar_unistroke_recognizer.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';

enum SnapShape { line, rectangle, ellipse }

// All in page-width units.
const double _minExtent = 0.01;
const double _spacing = 0.004;

// A stroke ending closer to its start than this share of its diagonal is a
// closed shape, every other one can only be a line.
const double _closedGap = 0.3;

const double _minLineScore = 0.5;
const double _minClosedScore = 0.78;

// tan(2 degrees), and the most the line end may sit off the axis in on-screen
// pixels. The angle alone would let a long line snap from far away.
const double _axisSnap = 0.035;
const double _axisSnapReach = 6;

final _lineTemplates = [
  Unistroke(SnapShape.line, const [Offset.zero, Offset(1, 0)]),
];

// $1 only compensates a rotation, not a different start along the outline, so
// the rectangle gets one template per start position on an edge.
final _closedTemplates = [
  Unistroke(SnapShape.ellipse, [
    for (var i = 0; i <= 32; i++)
      Offset(cos(2 * pi * i / 32), sin(2 * pi * i / 32)),
  ]),
  for (final t in const [0.0, 0.25, 0.5, 0.75])
    Unistroke(SnapShape.rectangle, [
      Offset(t, 0),
      const Offset(1, 0),
      const Offset(1, 1),
      const Offset(0, 1),
      Offset.zero,
      if (t > 0) Offset(t, 0),
    ]),
];

Rect _bounds(List<Offset> points) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final p in points) {
    minX = min(minX, p.dx);
    minY = min(minY, p.dy);
    maxX = max(maxX, p.dx);
    maxY = max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

// The recognizer rejects anything below its own resampling count.
List<Offset> _densify(List<Offset> points) {
  if (points.length >= Unistroke.numPoints) return points;
  final steps = (Unistroke.numPoints / (points.length - 1)).ceil();
  return [
    points.first,
    for (var i = 1; i < points.length; i++)
      for (var k = 1; k <= steps; k++)
        Offset.lerp(points[i - 1], points[i], k / steps)!,
  ];
}

// points are in page-width units, so distances are isotropic.
SnapShape? recognizeShape(List<Offset> points) {
  if (points.length < 2) return null;
  final box = _bounds(points);
  final diagonal = box.size.longestSide == 0
      ? 0.0
      : sqrt(box.width * box.width + box.height * box.height);
  if (diagonal < _minExtent) return null;

  if ((points.last - points.first).distance >= diagonal * _closedGap) {
    final match = recognizeCustomUnistroke<SnapShape>(
      _densify(points),
      overrideReferenceUnistrokes: _lineTemplates,
    );
    return match != null && match.score >= _minLineScore ? match.name : null;
  }

  if (box.shortestSide < _minExtent / 2) return null;
  // Stretched to a square first. The shapes snap axis-aligned anyway, and the
  // recognizer would otherwise skew a long rectangle while normalizing it.
  final match = recognizeCustomUnistroke<SnapShape>(
    _densify([
      for (final p in points)
        Offset((p.dx - box.left) / box.width, (p.dy - box.top) / box.height),
    ]),
    overrideReferenceUnistrokes: _closedTemplates,
  );
  return match != null && match.score >= _minClosedScore ? match.name : null;
}

// Everything below is in normalized page coordinates.

// pageWidth is the width the page currently has on screen.
Offset snapLineEnd(Offset from, Offset to, double aspect, double pageWidth) {
  final dx = (to.dx - from.dx).abs() * pageWidth;
  final dy = (to.dy - from.dy).abs() * aspect * pageWidth;
  if (dy < min(dx * _axisSnap, _axisSnapReach)) return Offset(to.dx, from.dy);
  if (dx < min(dy * _axisSnap, _axisSnapReach)) return Offset(from.dx, to.dy);
  return to;
}

List<StrokePoint> shapePoints(
  SnapShape shape,
  Offset from,
  Offset to, {
  required double aspect,
  required double width,
}) {
  final rect = Rect.fromPoints(from, to);
  // The outline is ragged within about a stroke width of both stroke ends, so
  // a closed shape runs past its start far enough to cover that.
  final overlap = 1.5 * width * max(1.0, aspect);
  final vertices = switch (shape) {
    SnapShape.line => [from, to],
    SnapShape.rectangle => _rectangle(rect, overlap),
    SnapShape.ellipse => _ellipse(rect, aspect, overlap),
  };
  final result = [_point(vertices.first)];
  for (var i = 1; i < vertices.length; i++) {
    final a = vertices[i - 1];
    final b = vertices[i];
    final length = Offset(b.dx - a.dx, (b.dy - a.dy) * aspect).distance;
    final steps = max(1, (length / _spacing).ceil());
    for (var k = 1; k <= steps; k++) {
      result.add(_point(Offset.lerp(a, b, k / steps)!));
    }
  }
  return result;
}

List<Offset> _rectangle(Rect rect, double overlap) {
  final reach = min(overlap, rect.width / 2);
  return [
    rect.topCenter.translate(-reach, 0),
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
    rect.topLeft,
    rect.topCenter.translate(reach, 0),
  ];
}

List<Offset> _ellipse(Rect rect, double aspect, double overlap) {
  final rx = rect.width / 2;
  final ry = rect.height / 2;
  final n = (pi * (rx + ry * aspect) / _spacing).ceil().clamp(24, 360);
  final step = 2 * pi / n;
  final extra = ry <= 0
      ? 0
      : (min(overlap / (ry * aspect), pi / 4) / step).ceil();
  return [
    for (var i = -extra; i <= n + extra; i++)
      Offset(
        rect.center.dx + rx * cos(step * i),
        rect.center.dy + ry * sin(step * i),
      ),
  ];
}

StrokePoint _point(Offset o) => StrokePoint(x: o.dx, y: o.dy, pressure: 0.5);
