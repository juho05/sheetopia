/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

class StrokePoint {
  final double x;
  final double y;
  final double pressure;

  const StrokePoint({required this.x, required this.y, required this.pressure});

  List<double> toJson() => [x, y, pressure];

  factory StrokePoint.fromJson(List<dynamic> json) => StrokePoint(
    x: (json[0] as num).toDouble(),
    y: (json[1] as num).toDouble(),
    pressure: json.length > 2 ? (json[2] as num).toDouble() : 0.5,
  );
}

class Stroke {
  final int colorValue;
  final double width;
  final List<StrokePoint> points;

  const Stroke({
    required this.colorValue,
    required this.width,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'c': colorValue,
    'w': width,
    'p': points.map((p) => p.toJson()).toList(),
  };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
    colorValue: json['c'] as int,
    width: (json['w'] as num).toDouble(),
    points: (json['p'] as List<dynamic>)
        .map((e) => StrokePoint.fromJson(e as List<dynamic>))
        .toList(),
  );
}

class PageAnnotations {
  final int pageIndex;
  final List<Stroke> strokes;

  const PageAnnotations({required this.pageIndex, required this.strokes});

  String encode() => jsonEncode(strokes.map((s) => s.toJson()).toList());

  factory PageAnnotations.decode(int pageIndex, String data) {
    final list = jsonDecode(data) as List<dynamic>;
    return PageAnnotations(
      pageIndex: pageIndex,
      strokes: list
          .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
