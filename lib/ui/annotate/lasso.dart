/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/stroke_outline.dart';

// Below this the two pages count as equally shaped and a paste is verbatim.
const double _aspectEpsilon = 0.001;

typedef Bounds = ({double minX, double minY, double maxX, double maxY});

Bounds? polygonBounds(List<double> polygon) {
  if (polygon.length < 4) return null;
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (var i = 0; i + 1 < polygon.length; i += 2) {
    final x = polygon[i];
    final y = polygon[i + 1];
    if (x < minX) minX = x;
    if (y < minY) minY = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
  }
  return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
}

// Flat normalized x/y pairs, implicitly closed. Even-odd ray cast, so the
// overlap region of a self-intersecting lasso counts as outside.
bool pointInPolygon(List<double> polygon, double x, double y) {
  final n = polygon.length ~/ 2;
  if (n < 3) return false;
  var inside = false;
  var jx = polygon[(n - 1) * 2];
  var jy = polygon[(n - 1) * 2 + 1];
  for (var i = 0; i < n; i++) {
    final ix = polygon[i * 2];
    final iy = polygon[i * 2 + 1];
    if ((iy > y) != (jy > y) &&
        x < (jx - ix) * (y - iy) / (jy - iy) + ix) {
      inside = !inside;
    }
    jx = ix;
    jy = iy;
  }
  return inside;
}

// Indices into strokes, ascending, of every stroke with at least one point
// inside the polygon.
List<int> selectStrokes(List<Stroke> strokes, List<double> polygon) {
  final box = polygonBounds(polygon);
  if (box == null) return const [];
  final result = <int>[];
  for (var i = 0; i < strokes.length; i++) {
    final stroke = strokes[i];
    if (stroke.points.isEmpty) continue;
    final b = stroke.bounds;
    if (b.minX > box.maxX ||
        b.maxX < box.minX ||
        b.minY > box.maxY ||
        b.maxY < box.minY) {
      continue;
    }
    for (final p in stroke.points) {
      if (pointInPolygon(polygon, p.x, p.y)) {
        result.add(i);
        break;
      }
    }
  }
  return result;
}

// The outline lives in the same normalized space as the points, so shifting it
// is exact and perfect_freehand never has to run again.
Stroke translateStroke(Stroke stroke, double dx, double dy) => Stroke(
  colorValue: stroke.colorValue,
  width: stroke.width,
  points: [
    for (final p in stroke.points)
      StrokePoint(
        x: roundCoord(p.x + dx),
        y: roundCoord(p.y + dy),
        pressure: p.pressure,
      ),
  ],
  outline: [
    for (var i = 0; i + 1 < stroke.outline.length; i += 2) ...[
      roundCoord(stroke.outline[i] + dx),
      roundCoord(stroke.outline[i + 1] + dy),
    ],
  ],
);

List<double> translatePolygon(List<double> polygon, double dx, double dy) => [
  for (var i = 0; i + 1 < polygon.length; i += 2) ...[
    polygon[i] + dx,
    polygon[i + 1] + dy,
  ],
];

// Returns the strokes remapped from a page of sourceAspect onto one of
// targetAspect, rebuilding outlines only when the aspects actually differ.
//
// x is already page-width relative and stays put; y is scaled about the top of
// the group's bounding box, and width by the ratio of the longer sides, so the
// strokes keep their physical size and shape relative to the page width.
List<Stroke> remapToAspect(
  List<Stroke> strokes,
  double sourceAspect,
  double targetAspect,
) {
  if (strokes.isEmpty || sourceAspect <= 0 || targetAspect <= 0) return strokes;
  if ((sourceAspect - targetAspect).abs() <= _aspectEpsilon) return strokes;

  final scaleY = sourceAspect / targetAspect;
  final scaleWidth = max(1.0, sourceAspect) / max(1.0, targetAspect);
  var anchorY = double.infinity;
  for (final stroke in strokes) {
    if (stroke.points.isEmpty) continue;
    anchorY = min(anchorY, stroke.bounds.minY);
  }
  if (!anchorY.isFinite) anchorY = 0;

  return [
    for (final stroke in strokes)
      _remapStroke(stroke, anchorY, scaleY, scaleWidth, targetAspect),
  ];
}

Stroke _remapStroke(
  Stroke stroke,
  double anchorY,
  double scaleY,
  double scaleWidth,
  double targetAspect,
) {
  final points = [
    for (final p in stroke.points)
      StrokePoint(
        x: roundCoord(p.x),
        y: roundCoord(anchorY + (p.y - anchorY) * scaleY),
        pressure: p.pressure,
      ),
  ];
  final width = stroke.width * scaleWidth;
  return Stroke(
    colorValue: stroke.colorValue,
    width: width,
    points: points,
    outline: buildOutline(
      points: points,
      width: width,
      aspect: targetAspect,
    ),
  );
}
