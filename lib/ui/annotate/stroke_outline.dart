/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:perfect_freehand/perfect_freehand.dart' hide StrokePoint;
import 'package:sheetopia/data/repositories/scores/stroke.dart';

// The outline is built in a fixed-size reference space instead of the real
// render size. perfect_freehand's sharp-corner threshold is `size / 128`
// compared against a unit-vector dot product (max 1.0), so a large `size` at
// high zoom flags every point as a corner and turns the stroke into a chain of
// caps. Keeping `size` fixed avoids that and makes the stored outline
// scale-invariant.
const double _refWidth = 1000.0;

// Returns the baked outline as flat normalized (0..1) x/y pairs.
List<double> buildOutline({
  required List<StrokePoint> points,
  required double width,
  required double aspect,
}) {
  final refHeight = _refWidth * aspect;
  final outline = getStroke(
    points
        .map((p) => PointVector(p.x * _refWidth, p.y * refHeight, p.pressure))
        .toList(),
    options: StrokeOptions(
      size: width * max(_refWidth, refHeight),
      isComplete: true,
      simulatePressure: false,
      // points are already streamlined
      streamline: 0,
    ),
  );
  final result = <double>[];
  for (final o in outline) {
    result.add(roundCoord(o.dx / _refWidth));
    result.add(roundCoord(o.dy / refHeight));
  }
  return result;
}
