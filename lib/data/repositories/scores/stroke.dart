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

String? encodeAnnotations(Map<int, List<Stroke>> pages) {
  final result = <String, dynamic>{};
  for (final entry in pages.entries) {
    if (entry.value.isEmpty) continue;
    result['${entry.key}'] = entry.value.map((s) => s.toJson()).toList();
  }
  if (result.isEmpty) return null;
  return jsonEncode(result);
}

Map<int, List<Stroke>> decodeAnnotations(String? data) {
  if (data == null || data.isEmpty) return {};
  final json = jsonDecode(data) as Map<String, dynamic>;
  return json.map(
    (key, value) => MapEntry(
      int.parse(key),
      (value as List<dynamic>)
          .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
}
