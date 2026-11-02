/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:typed_data';

import 'package:sheetopia/data/services/score_processing/background_color.dart';

/// The empty space of a page as fractions of the page width and height.
class PageMargins {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const PageMargins({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const zero = PageMargins(left: 0, top: 0, right: 0, bottom: 0);

  /// A page without content is all margin, so it never limits other pages.
  static const blank = PageMargins(left: 1, top: 1, right: 1, bottom: 1);

  @override
  bool operator ==(Object other) =>
      other is PageMargins &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => "PageMargins($left, $top, $right, $bottom)";
}

// Pixels with luminance within this tolerance from the background color
// count as background that can be cropped.
const _inkSlack = 16;

const _minInkPixels = 3;
const _minInkFraction = 0.005;

// How much of edge content to ignore if it is followed by background.
// Used to skip dark edges of scans.
const _maxEdgeBandFraction = 0.015;
const _minEdgeGapFraction = 0.005;

// Declare margin detection as failed if two opposing sides have more margin than this.
const _maxSmallerMargin = 0.25;

// Max margin per axis. E.g. if top 0.6 and bottom 0.1 are detected,
// it results in top 0.4 and bottom 0.1.
const _maxAxisMargin = 0.5;

/// Returns null if any page cannot be reliably determined.
PageMargins? combinePageMargins(Iterable<PageMargins?> pages) {
  if (pages.isEmpty || pages.contains(null)) return null;
  final left = pages.map((m) => m!.left).reduce(min);
  final top = pages.map((m) => m!.top).reduce(min);
  final right = pages.map((m) => m!.right).reduce(min);
  final bottom = pages.map((m) => m!.bottom).reduce(min);
  if (min(left, right) > _maxSmallerMargin ||
      min(top, bottom) > _maxSmallerMargin) {
    return null;
  }
  final (limitedLeft, limitedRight) = _limitAxis(left, right);
  final (limitedTop, limitedBottom) = _limitAxis(top, bottom);
  return PageMargins(
    left: limitedLeft,
    top: limitedTop,
    right: limitedRight,
    bottom: limitedBottom,
  );
}

(double, double) _limitAxis(double a, double b) {
  if (a + b <= _maxAxisMargin) return (a, b);
  return a > b ? (_maxAxisMargin - b, b) : (a, _maxAxisMargin - a);
}

/// Returns null if the margins cannot be reliably determined.
PageMargins? estimatePageMargins(PageBitmap page, PageBackground? background) {
  if (background == null || !background.hasReliablePaper) return null;
  final width = page.width;
  final height = page.height;

  final low = background.paperLow - _inkSlack;
  final high = background.paperHigh + _inkSlack;
  final bandX = (width * _maxEdgeBandFraction).floor();
  final bandY = (height * _maxEdgeBandFraction).floor();
  final rows = Int32List(height);
  final columns = Int32List(width);
  final ink = Uint8List(width * height);
  for (var y = 0, i = 0; y < height; y++) {
    final inBandY = y < bandY || y >= height - bandY;
    for (var x = 0; x < width; x++, i += 4) {
      final l = luminanceAt(page.bgra, i);
      if (l >= low && l <= high) continue;
      ink[y * width + x] = 1;
      // An edge band would look like content along the whole other axis.
      if (x >= bandX && x < width - bandX) rows[y]++;
      if (!inBandY) columns[x]++;
    }
  }

  final columnThreshold = max(_minInkPixels, height * _minInkFraction);
  final rowThreshold = max(_minInkPixels, width * _minInkFraction);
  final left = _margin(columns, columnThreshold, bandX);
  final right = _margin(columns.reversed.toList(), columnThreshold, bandX);
  final top = _margin(rows, rowThreshold, bandY);
  final bottom = _margin(rows.reversed.toList(), rowThreshold, bandY);
  if (left == null || right == null || top == null || bottom == null) {
    // Only an edge band leaves a side without content on both axes. Content
    // could also hide in a truncated paper range.
    final isBlank =
        (left == null || right == null) &&
        (top == null || bottom == null) &&
        !background.paperTruncated;
    return isBlank ? PageMargins.blank : null;
  }
  final marks = _markBounds(
    ink,
    width,
    height,
    minMarkWidth: rowThreshold,
    minMarkHeight: columnThreshold,
    bandX: bandX,
    bandY: bandY,
  );
  return PageMargins(
    left: (marks == null ? left : min(left, marks.left)) / width,
    top: (marks == null ? top : min(top, marks.top)) / height,
    right: (marks == null ? right : min(right, marks.right)) / width,
    bottom: (marks == null ? bottom : min(bottom, marks.bottom)) / height,
  );
}

/// The margins left by all connected marks that are large enough on one axis,
/// so a thin mark found on one axis also counts for the other. Clears [ink].
///
/// Marks reaching the edge band are skipped, because a scan edge or a dirt line
/// must not void the crop of the other axis.
({int left, int top, int right, int bottom})? _markBounds(
  Uint8List ink,
  int width,
  int height, {
  required num minMarkWidth,
  required num minMarkHeight,
  required int bandX,
  required int bandY,
}) {
  final stack = Int32List(ink.length);
  var left = width;
  var top = height;
  var right = -1;
  var bottom = -1;
  for (var start = 0; start < ink.length; start++) {
    if (ink[start] == 0) continue;
    ink[start] = 0;
    stack[0] = start;
    var size = 1;
    var markLeft = width;
    var markTop = height;
    var markRight = -1;
    var markBottom = -1;
    while (size > 0) {
      final pixel = stack[--size];
      final x = pixel % width;
      final y = pixel ~/ width;
      markLeft = min(markLeft, x);
      markTop = min(markTop, y);
      markRight = max(markRight, x);
      markBottom = max(markBottom, y);
      for (var ny = max(0, y - 1); ny <= min(height - 1, y + 1); ny++) {
        for (var nx = max(0, x - 1); nx <= min(width - 1, x + 1); nx++) {
          final neighbor = ny * width + nx;
          if (ink[neighbor] == 0) continue;
          ink[neighbor] = 0;
          stack[size++] = neighbor;
        }
      }
    }
    if (markLeft < bandX ||
        markTop < bandY ||
        markRight >= width - bandX ||
        markBottom >= height - bandY) {
      continue;
    }
    if (markRight - markLeft + 1 < minMarkWidth &&
        markBottom - markTop + 1 < minMarkHeight) {
      continue;
    }
    left = min(left, markLeft);
    top = min(top, markTop);
    right = max(right, markRight);
    bottom = max(bottom, markBottom);
  }
  if (right < 0) return null;
  return (
    left: left,
    top: top,
    right: width - 1 - right,
    bottom: height - 1 - bottom,
  );
}

int? _margin(List<int> lines, num threshold, int maxBand) {
  final minGap = (lines.length * _minEdgeGapFraction).ceil();
  int? last;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i] < threshold) continue;
    if (last == null && i > 0) return i;
    if (last != null && i - last - 1 >= minGap) return i;
    if (i >= maxBand) return 0;
    last = i;
  }
  return null;
}
