/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/annotate/shape_snap.dart';

// A hand is never exact, and an exact match is also the one input the
// recognizer trips over.
List<Offset> _wobble(List<Offset> points, [double amount = 0.004]) => [
  for (var i = 0; i < points.length; i++)
    points[i] + Offset(sin(i * 1.7), cos(i * 2.3)) * amount,
];

// start shifts the first point along the outline, as a share of it.
List<Offset> _polygon(List<Offset> vertices, {double start = 0}) {
  final points = <Offset>[];
  for (var i = 0; i < vertices.length; i++) {
    final a = vertices[i];
    final b = vertices[(i + 1) % vertices.length];
    for (var k = 0; k < 12; k++) {
      points.add(Offset.lerp(a, b, k / 12)!);
    }
  }
  final shift = (start * points.length).round();
  return [...points.skip(shift), ...points.take(shift), points[shift]];
}

List<Offset> _rect(Rect r, {double start = 0}) => _polygon([
  r.topLeft,
  r.topRight,
  r.bottomRight,
  r.bottomLeft,
], start: start);

List<Offset> _ellipse(Rect r, {double from = 0, double sweep = 1}) => [
  for (var i = 0; i <= 60; i++)
    r.center +
        Offset(
          r.width / 2 * cos(from + 2 * pi * sweep * i / 60),
          r.height / 2 * sin(from + 2 * pi * sweep * i / 60),
        ),
];

void main() {
  group('recognizeShape', () {
    test('a straight stroke is a line in every direction', () {
      for (final end in const [
        Offset(0.6, 0.2),
        Offset(0.2, 0.7),
        Offset(0.5, 0.6),
        Offset(0.05, 0.3),
      ]) {
        final points = [
          for (var i = 0; i <= 20; i++)
            Offset.lerp(const Offset(0.2, 0.2), end, i / 20)!,
        ];
        expect(recognizeShape(_wobble(points, 0.002)), SnapShape.line);
      }
    });

    test('two samples are enough for a line', () {
      expect(
        recognizeShape(const [Offset(0.2, 0.2), Offset(0.6, 0.5)]),
        SnapShape.line,
      );
    });

    test('rectangles of any proportion, start and direction', () {
      for (final rect in const [
        Rect.fromLTWH(0.2, 0.2, 0.3, 0.3),
        Rect.fromLTWH(0.1, 0.2, 0.6, 0.1),
        Rect.fromLTWH(0.3, 0.1, 0.1, 0.5),
      ]) {
        for (final start in const [0.0, 0.06, 0.125, 0.3, 0.62]) {
          final points = _wobble(_rect(rect, start: start));
          expect(recognizeShape(points), SnapShape.rectangle);
          expect(recognizeShape(points.reversed.toList()), SnapShape.rectangle);
        }
      }
    });

    test('ellipses of any proportion, start and direction', () {
      for (final rect in const [
        Rect.fromLTWH(0.2, 0.2, 0.3, 0.3),
        Rect.fromLTWH(0.1, 0.2, 0.6, 0.15),
        Rect.fromLTWH(0.3, 0.1, 0.1, 0.5),
      ]) {
        for (final from in const [0.0, 1.0, 2.5, 4.0]) {
          final points = _wobble(_ellipse(rect, from: from));
          expect(recognizeShape(points), SnapShape.ellipse);
          expect(recognizeShape(points.reversed.toList()), SnapShape.ellipse);
        }
      }
    });

    test('an ellipse that stops short or overshoots still counts', () {
      const rect = Rect.fromLTWH(0.2, 0.2, 0.4, 0.2);
      expect(
        recognizeShape(_wobble(_ellipse(rect, sweep: 0.92))),
        SnapShape.ellipse,
      );
      expect(
        recognizeShape(_wobble(_ellipse(rect, sweep: 1.08))),
        SnapShape.ellipse,
      );
    });

    test('other strokes stay freehand', () {
      final triangle = _polygon(const [
        Offset(0.4, 0.2),
        Offset(0.6, 0.5),
        Offset(0.2, 0.5),
      ]);
      final arc = _ellipse(const Rect.fromLTWH(0.2, 0.2, 0.4, 0.4), sweep: 0.5);
      final corner = [
        for (var i = 0; i <= 10; i++) Offset(0.2 + i * 0.03, 0.2),
        for (var i = 1; i <= 10; i++) Offset(0.5, 0.2 + i * 0.03),
      ];
      final zigzag = [
        for (var i = 0; i <= 20; i++)
          Offset(0.2 + i * 0.02, i.isEven ? 0.2 : 0.3),
      ];
      final dot = [for (var i = 0; i <= 10; i++) Offset(0.2 + i * 0.0003, 0.2)];
      expect(recognizeShape(_wobble(triangle)), isNull);
      expect(recognizeShape(_wobble(arc)), isNull);
      expect(recognizeShape(_wobble(corner)), isNull);
      expect(recognizeShape(_wobble(zigzag)), isNull);
      expect(recognizeShape(dot), isNull);
    });
  });

  group('shapePoints', () {
    test('a rectangle runs past its start and reaches all four corners', () {
      final points = shapePoints(
        SnapShape.rectangle,
        const Offset(0.6, 0.5),
        const Offset(0.2, 0.3),
        aspect: 1.4,
        width: 0.004,
      );
      expect(points.first.x, lessThan(0.4));
      expect(points.last.x, greaterThan(0.4));
      expect(points.first.y, 0.3);
      expect(points.last.y, 0.3);
      for (final corner in const [
        Offset(0.2, 0.3),
        Offset(0.6, 0.3),
        Offset(0.6, 0.5),
        Offset(0.2, 0.5),
      ]) {
        expect(
          points.any(
            (p) =>
                (p.x - corner.dx).abs() < 1e-9 &&
                (p.y - corner.dy).abs() < 1e-9,
          ),
          isTrue,
        );
      }
    });

    test('an ellipse stays on its outline', () {
      final points = shapePoints(
        SnapShape.ellipse,
        const Offset(0.2, 0.3),
        const Offset(0.6, 0.5),
        aspect: 1.4,
        width: 0.004,
      );
      for (final p in points) {
        final x = (p.x - 0.4) / 0.2;
        final y = (p.y - 0.4) / 0.1;
        expect(x * x + y * y, closeTo(1, 1e-3));
      }
    });

    test('a line is sampled densely enough for the lasso to catch', () {
      final points = shapePoints(
        SnapShape.line,
        const Offset(0.1, 0.1),
        const Offset(0.9, 0.1),
        aspect: 1.4,
        width: 0.004,
      );
      expect(points.length, greaterThan(100));
    });
  });

  test('a line end snaps to the axes only when close to them', () {
    const from = Offset(0.2, 0.2);
    expect(
      snapLineEnd(from, const Offset(0.4, 0.203), 1.4, 1000),
      const Offset(0.4, 0.2),
    );
    expect(
      snapLineEnd(from, const Offset(0.203, 0.4), 1.4, 1000),
      const Offset(0.2, 0.4),
    );
    // inside the angle, but too many pixels off the axis
    expect(
      snapLineEnd(from, const Offset(0.9, 0.21), 1.4, 1000),
      const Offset(0.9, 0.21),
    );
    // few pixels off the axis, but too steep for a line this short
    expect(
      snapLineEnd(from, const Offset(0.25, 0.203), 1.4, 1000),
      const Offset(0.25, 0.203),
    );
    // the same line zoomed in is further off on screen
    expect(
      snapLineEnd(from, const Offset(0.4, 0.203), 1.4, 3000),
      const Offset(0.4, 0.203),
    );
    expect(
      snapLineEnd(from, const Offset(0.9, 0.21), 1.4, 300),
      const Offset(0.9, 0.2),
    );
    expect(
      snapLineEnd(from, const Offset(0.6, 0.3), 1.4, 1000),
      const Offset(0.6, 0.3),
    );
  });
}
