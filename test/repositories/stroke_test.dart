/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';

Stroke _stroke({
  int colorValue = 0xFFFF0000,
  double width = 0.004,
  List<StrokePoint>? points,
  List<double>? outline,
}) => Stroke(
  colorValue: colorValue,
  width: width,
  points:
      points ??
      const [
        StrokePoint(x: 0.1, y: 0.2, pressure: 0.5),
        StrokePoint(x: 0.3, y: 0.4, pressure: 0.5),
      ],
  outline: outline ?? const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6],
);

void main() {
  group('encode/decode', () {
    test('round-trips color, width, points and outline', () {
      final original = _stroke();
      final decoded = decodeAnnotations(
        encodeAnnotations({
          3: [original],
        }),
      );

      expect(decoded.keys, [3]);
      final stroke = decoded[3]!.single;
      expect(stroke.colorValue, original.colorValue);
      expect(stroke.width, original.width);
      expect(stroke.points.length, original.points.length);
      for (var i = 0; i < stroke.points.length; i++) {
        expect(stroke.points[i].x, original.points[i].x);
        expect(stroke.points[i].y, original.points[i].y);
        expect(stroke.points[i].pressure, original.points[i].pressure);
      }
      expect(stroke.outline, original.outline);
    });

    test('preserves outline coordinates at 5-decimal precision', () {
      const outline = [0.12345, 0.98765, 0.00001, 0.99999];
      final decoded = decodeAnnotations(
        encodeAnnotations({
          0: [_stroke(outline: outline)],
        }),
      );

      expect(decoded[0]!.single.outline, outline);
    });

    test('drops strokes without an outline', () {
      final data = jsonEncode({
        '1': [
          {
            'c': 0xFFFF0000,
            'w': 0.004,
            'p': [
              [0.1, 0.2, 0.5],
            ],
          },
          _stroke().toJson(),
        ],
      });

      expect(decodeAnnotations(data)[1], hasLength(1));
    });

    test('drops pages left empty after filtering', () {
      final data = jsonEncode({
        '1': [
          {
            'c': 0xFFFF0000,
            'w': 0.004,
            'p': [
              [0.1, 0.2, 0.5],
            ],
          },
        ],
        '2': [
          {
            'c': 0xFFFF0000,
            'w': 0.004,
            'p': [
              [0.1, 0.2, 0.5],
            ],
            'o': <double>[],
          },
        ],
        '4': [_stroke().toJson()],
      });

      expect(decodeAnnotations(data).keys, [4]);
    });

    test('encodeAnnotations returns null when everything is empty', () {
      expect(encodeAnnotations({}), isNull);
      expect(encodeAnnotations({0: [], 1: []}), isNull);
    });

    test('decodeAnnotations handles null and empty input', () {
      expect(decodeAnnotations(null), isEmpty);
      expect(decodeAnnotations(''), isEmpty);
    });
  });

  test('rounded() quantizes x/y to 5 decimals and keeps pressure', () {
    const p = StrokePoint(x: 0.123456789, y: 0.987654321, pressure: 0.25);
    final r = p.rounded();

    expect(r.x, 0.12346);
    expect(r.y, 0.98765);
    expect(r.pressure, 0.25);
    expect(r.rounded().x, r.x);
    expect(r.rounded().y, r.y);
  });

  test('bounds are computed from the raw points', () {
    final stroke = _stroke(
      points: const [
        StrokePoint(x: 0.4, y: 0.9, pressure: 0.5),
        StrokePoint(x: 0.1, y: 0.3, pressure: 0.5),
        StrokePoint(x: 0.7, y: 0.5, pressure: 0.5),
      ],
      outline: const [0.0, 0.0, 1.0, 1.0],
    );

    expect(stroke.bounds.minX, 0.1);
    expect(stroke.bounds.minY, 0.3);
    expect(stroke.bounds.maxX, 0.7);
    expect(stroke.bounds.maxY, 0.9);
  });
}
