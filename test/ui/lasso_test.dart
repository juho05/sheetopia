/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/lasso.dart';
import 'package:sheetopia/ui/annotate/stroke_outline.dart';

const _square = [0.2, 0.2, 0.8, 0.2, 0.8, 0.8, 0.2, 0.8];

// A U opening upwards: the notch between the two prongs is outside.
const _u = [
  0.2, 0.2, //
  0.4, 0.2,
  0.4, 0.7,
  0.6, 0.7,
  0.6, 0.2,
  0.8, 0.2,
  0.8, 0.9,
  0.2, 0.9,
];

// A pentagram: the middle is wound twice, the five tips once.
const _star = [
  0.5, 0.1, //
  0.73512, 0.82361,
  0.11958, 0.37639,
  0.88042, 0.37639,
  0.26488, 0.82361,
];

Stroke _stroke(List<(double, double)> points, {double width = 0.004}) {
  final strokePoints = [
    for (final (x, y) in points) StrokePoint(x: x, y: y, pressure: 0.5),
  ];
  return Stroke(
    colorValue: 0xFFFF0000,
    width: width,
    points: strokePoints,
    outline: buildOutline(points: strokePoints, width: width, aspect: 1.4),
  );
}

({double x, double y}) _outlineExtent(Stroke stroke) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (var i = 0; i + 1 < stroke.outline.length; i += 2) {
    final x = stroke.outline[i];
    final y = stroke.outline[i + 1];
    if (x < minX) minX = x;
    if (y < minY) minY = y;
    if (x > maxX) maxX = x;
    if (y > maxY) maxY = y;
  }
  return (x: maxX - minX, y: maxY - minY);
}

void main() {
  group('pointInPolygon', () {
    test('convex square', () {
      expect(pointInPolygon(_square, 0.5, 0.5), isTrue);
      expect(pointInPolygon(_square, 0.21, 0.79), isTrue);
      expect(pointInPolygon(_square, 0.5, 0.1), isFalse);
      expect(pointInPolygon(_square, 0.9, 0.5), isFalse);
    });

    test('concave U shape excludes the notch', () {
      expect(pointInPolygon(_u, 0.3, 0.5), isTrue);
      expect(pointInPolygon(_u, 0.7, 0.5), isTrue);
      expect(pointInPolygon(_u, 0.5, 0.85), isTrue);
      expect(pointInPolygon(_u, 0.5, 0.4), isFalse);
    });

    test('a vertex follows the half-open ray-cast rule', () {
      // Top-left counts as in, bottom-right as out, so tiling polygons never
      // claim the same point twice.
      expect(pointInPolygon(_square, 0.2, 0.2), isTrue);
      expect(pointInPolygon(_square, 0.8, 0.8), isFalse);
    });

    test('point outside the bounding box', () {
      expect(pointInPolygon(_square, -1, -1), isFalse);
      expect(pointInPolygon(_square, 2, 0.5), isFalse);
    });

    test('even-odd: a self-intersecting lasso excludes its own overlap', () {
      expect(pointInPolygon(_star, 0.5, 0.2), isTrue);
      expect(pointInPolygon(_star, 0.5, 0.5), isFalse);
    });

    test('degenerate polygons are empty', () {
      expect(pointInPolygon(const [], 0.5, 0.5), isFalse);
      expect(pointInPolygon(const [0.1, 0.1, 0.9, 0.9], 0.5, 0.5), isFalse);
    });
  });

  group('selectStrokes', () {
    test('picks fully inside, skips fully outside', () {
      final inside = _stroke([(0.3, 0.3), (0.5, 0.5)]);
      final outside = _stroke([(0.9, 0.9), (0.95, 0.95)]);
      expect(selectStrokes([inside, outside], _square), [0]);
    });

    test('a single point inside is enough', () {
      final grazing = _stroke([(0.05, 0.05), (0.25, 0.25), (0.95, 0.95)]);
      expect(selectStrokes([grazing], _square), [0]);
    });

    test('an overlapping bounding box alone does not select', () {
      // Runs through the notch of the U, so its box overlaps but no point is in.
      final throughNotch = _stroke([(0.45, 0.3), (0.55, 0.3), (0.5, 0.5)]);
      expect(selectStrokes([throughNotch], _u), isEmpty);
    });

    test('indices are ascending positions in the page list', () {
      final a = _stroke([(0.3, 0.3)]);
      final b = _stroke([(0.9, 0.9)]);
      final c = _stroke([(0.4, 0.4)]);
      expect(selectStrokes([a, b, c], _square), [0, 2]);
    });
  });

  group('translateStroke', () {
    test('shifts points and outline, keeps colour and width', () {
      final original = _stroke([(0.3, 0.3), (0.5, 0.5)]);
      final moved = translateStroke(original, 0.1, -0.05);

      expect(moved.colorValue, original.colorValue);
      expect(moved.width, original.width);
      expect(moved.points.length, original.points.length);
      for (var i = 0; i < moved.points.length; i++) {
        expect(moved.points[i].x, closeTo(original.points[i].x + 0.1, 1e-5));
        expect(moved.points[i].y, closeTo(original.points[i].y - 0.05, 1e-5));
        expect(moved.points[i].pressure, original.points[i].pressure);
      }
      expect(moved.outline.length, original.outline.length);
      for (var i = 0; i + 1 < moved.outline.length; i += 2) {
        expect(moved.outline[i], closeTo(original.outline[i] + 0.1, 1e-5));
        expect(
          moved.outline[i + 1],
          closeTo(original.outline[i + 1] - 0.05, 1e-5),
        );
      }
    });

    test('coordinates stay rounded to the stored precision', () {
      final moved = translateStroke(_stroke([(0.3, 0.3)]), 0.123456789, 0);
      for (final p in moved.points) {
        expect(p.x, roundCoord(p.x));
        expect(p.y, roundCoord(p.y));
      }
      for (final v in moved.outline) {
        expect(v, roundCoord(v));
      }
    });

    test('bounds are recomputed on the new instance', () {
      final original = _stroke([(0.3, 0.3), (0.5, 0.5)]);
      expect(original.bounds.minX, closeTo(0.3, 1e-9));
      final moved = translateStroke(original, 0.2, 0.2);
      expect(moved.bounds.minX, closeTo(0.5, 1e-5));
      expect(moved.bounds.maxY, closeTo(0.7, 1e-5));
    });

    test('translating back returns to the original coordinates', () {
      final original = _stroke([(0.3, 0.31), (0.52, 0.5)]);
      final round = translateStroke(
        translateStroke(original, 0.07, 0.11),
        -0.07,
        -0.11,
      );
      for (var i = 0; i < round.points.length; i++) {
        expect(round.points[i].x, closeTo(original.points[i].x, 1e-5));
        expect(round.points[i].y, closeTo(original.points[i].y, 1e-5));
      }
      for (var i = 0; i < round.outline.length; i++) {
        expect(round.outline[i], closeTo(original.outline[i], 1e-5));
      }
    });
  });

  test('translatePolygon shifts every vertex', () {
    final moved = translatePolygon(_square, 0.1, 0.2);
    expect(moved, [
      closeTo(0.3, 1e-9),
      closeTo(0.4, 1e-9),
      closeTo(0.9, 1e-9),
      closeTo(0.4, 1e-9),
      closeTo(0.9, 1e-9),
      closeTo(1.0, 1e-9),
      closeTo(0.3, 1e-9),
      closeTo(1.0, 1e-9),
    ]);
  });

  group('remapToAspect', () {
    test('equal aspects return the very same instances', () {
      final strokes = [_stroke([(0.3, 0.3), (0.5, 0.5)])];
      final remapped = remapToAspect(strokes, 1.4, 1.4);
      expect(identical(remapped, strokes), isTrue);
      expect(identical(remapped[0].outline, strokes[0].outline), isTrue);
    });

    test('a taller target page compresses y and shrinks width', () {
      final strokes = [
        _stroke([(0.2, 0.2), (0.2, 0.6)]),
      ];
      final remapped = remapToAspect(strokes, 1.4, 2.8);

      expect(remapped[0].width, closeTo(strokes[0].width * 1.4 / 2.8, 1e-9));
      // x is page-width relative and stays put.
      expect(remapped[0].points[0].x, closeTo(0.2, 1e-5));
      expect(remapped[0].points[1].x, closeTo(0.2, 1e-5));
      // y scales about the top of the group, halving the height.
      expect(remapped[0].points[0].y, closeTo(0.2, 1e-5));
      expect(remapped[0].points[1].y, closeTo(0.4, 1e-5));
    });

    test('relative positions inside the group survive the remap', () {
      final strokes = [
        _stroke([(0.1, 0.2)]),
        _stroke([(0.1, 0.6)]),
      ];
      final remapped = remapToAspect(strokes, 1.4, 2.8);
      expect(remapped[0].points[0].y, closeTo(0.2, 1e-5));
      expect(remapped[1].points[0].y, closeTo(0.4, 1e-5));
    });

    test('the remapped outline keeps a uniform thickness in both axes', () {
      const source = 1.4;
      const target = 2.8;
      final horizontal = remapToAspect(
        [
          _stroke([(0.2, 0.4), (0.6, 0.4)]),
        ],
        source,
        target,
      )[0];
      final vertical = remapToAspect(
        [
          _stroke([(0.4, 0.2), (0.4, 0.6)]),
        ],
        source,
        target,
      )[0];

      // Thickness in page-width units: across a horizontal stroke that is the
      // y extent scaled by the target aspect, across a vertical one the raw x
      // extent. A naive scale of the baked outline makes the two disagree.
      final acrossHorizontal = _outlineExtent(horizontal).y * target;
      final acrossVertical = _outlineExtent(vertical).x;
      expect(acrossHorizontal, closeTo(acrossVertical, acrossVertical * 0.02));
    });

    test('non-positive aspects are left alone', () {
      final strokes = [_stroke([(0.3, 0.3)])];
      expect(identical(remapToAspect(strokes, 0, 1.4), strokes), isTrue);
      expect(identical(remapToAspect(strokes, 1.4, 0), strokes), isTrue);
    });
  });
}
