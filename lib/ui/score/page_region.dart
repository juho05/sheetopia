/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:ui';

import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/score_processing/page_margins.dart';

const fullPageRegion = Rect.fromLTRB(0, 0, 1, 1);

Rect? strokesBounds(Iterable<Stroke> strokes) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final stroke in strokes) {
    final outline = stroke.outline;
    for (var i = 0; i + 1 < outline.length; i += 2) {
      if (outline[i] < minX) minX = outline[i];
      if (outline[i] > maxX) maxX = outline[i];
      if (outline[i + 1] < minY) minY = outline[i + 1];
      if (outline[i + 1] > maxY) maxY = outline[i + 1];
    }
  }
  return minX.isFinite ? Rect.fromLTRB(minX, minY, maxX, maxY) : null;
}

PageMargins? strokeInsets(Map<int, List<Stroke>> pages) {
  final bounds = strokesBounds(pages.values.expand((strokes) => strokes));
  if (bounds == null) return null;
  return PageMargins(
    left: bounds.left,
    top: bounds.top,
    right: 1 - bounds.right,
    bottom: 1 - bounds.bottom,
  );
}

Rect visiblePageRegion({
  required Size pageSize,
  required PageMargins margins,
  required double padding,
  PageMargins? strokes,
}) {
  final longSide = pageSize.longestSide;
  final paddingX = padding * longSide / pageSize.width;
  final paddingY = padding * longSide / pageSize.height;
  double crop(double margin, double pad, double? stroke) {
    final cropped = margin - pad;
    return (stroke != null && stroke < cropped ? stroke : cropped).clamp(
      0.0,
      1.0,
    );
  }

  return Rect.fromLTRB(
    crop(margins.left, paddingX, strokes?.left),
    crop(margins.top, paddingY, strokes?.top),
    1 - crop(margins.right, paddingX, strokes?.right),
    1 - crop(margins.bottom, paddingY, strokes?.bottom),
  );
}
