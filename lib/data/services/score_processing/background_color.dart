/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:typed_data';

class PageBitmap {
  final int width;
  final int height;
  final Uint8List bgra;

  const PageBitmap({
    required this.width,
    required this.height,
    required this.bgra,
  });
}

class PageBackground {
  final int r;
  final int g;
  final int b;

  /// Fraction of the analyzed area that has the background color.
  final double coverage;

  const PageBackground({
    required this.r,
    required this.g,
    required this.b,
    required this.coverage,
  });

  int get argb => 0xFF000000 | (r << 16) | (g << 8) | b;
}

const _maxSamples = 200000;
const _smoothingRadius = 4;
const _bandThreshold = 0.2;
const _maxBandRadius = 48;
const _minCoverage = 0.15;

/// Returns the background color of the score as ARGB or null if no page has a
/// dominant background.
int? combinePageBackgrounds(Iterable<PageBackground> pages) {
  final backgrounds = pages.where((b) => b.coverage >= _minCoverage).toList();
  if (backgrounds.isEmpty) return null;

  return PageBackground(
    r: _weightedMedian(backgrounds, (b) => b.r),
    g: _weightedMedian(backgrounds, (b) => b.g),
    b: _weightedMedian(backgrounds, (b) => b.b),
    coverage: 1,
  ).argb;
}

/// Finds the luminance peak covering the most pixels and returns the median
/// color of all pixels within the peak. Content like notes and the surface around
/// imperfectly cropped scans cover less area than the paper, uneven lighting
/// only broadens the peak.
PageBackground? estimatePageBackground(PageBitmap page) {
  final step = max(1, sqrt(page.width * page.height / _maxSamples).ceil());

  final luminance = Int32List(256);
  var total = 0;
  for (var y = 0; y < page.height; y += step) {
    var i = y * page.width * 4;
    for (var x = 0; x < page.width; x += step, i += step * 4) {
      luminance[_luminance(page.bgra, i)]++;
      total++;
    }
  }
  if (total == 0) return null;

  final smoothed = Float64List(256);
  for (var l = 0; l < 256; l++) {
    var sum = 0;
    for (
      var k = max(0, l - _smoothingRadius);
      k <= min(255, l + _smoothingRadius);
      k++
    ) {
      sum += luminance[k];
    }
    smoothed[l] = sum.toDouble();
  }

  // A flat surface forms a narrow spike, paper under uneven lighting a wide
  // hill. Comparing the pixel count of each peak band prefers the larger area.
  var low = 0;
  var high = 0;
  var bestMass = -1;
  for (var peak = 0; peak < 256; peak++) {
    final value = smoothed[peak];
    if (value == 0) continue;
    if (peak > 0 && smoothed[peak - 1] > value) continue;
    if (peak < 255 && smoothed[peak + 1] >= value) continue;

    final (bandLow, bandHigh) = _peakBand(smoothed, peak);
    var mass = 0;
    for (var l = bandLow; l <= bandHigh; l++) {
      mass += luminance[l];
    }
    if (mass > bestMass) {
      bestMass = mass;
      low = bandLow;
      high = bandHigh;
    }
  }

  final rHist = Int32List(256);
  final gHist = Int32List(256);
  final bHist = Int32List(256);
  var count = 0;
  for (var y = 0; y < page.height; y += step) {
    var i = y * page.width * 4;
    for (var x = 0; x < page.width; x += step, i += step * 4) {
      final l = _luminance(page.bgra, i);
      if (l < low || l > high) continue;
      bHist[page.bgra[i]]++;
      gHist[page.bgra[i + 1]]++;
      rHist[page.bgra[i + 2]]++;
      count++;
    }
  }
  if (count == 0) return null;

  return PageBackground(
    r: _histogramMedian(rHist, count),
    g: _histogramMedian(gHist, count),
    b: _histogramMedian(bHist, count),
    coverage: count / total,
  );
}

(int, int) _peakBand(Float64List smoothed, int peak) {
  final threshold = smoothed[peak] * _bandThreshold;
  var low = peak;
  while (low > 0 &&
      peak - low < _maxBandRadius &&
      smoothed[low - 1] >= threshold) {
    low--;
  }
  var high = peak;
  while (high < 255 &&
      high - peak < _maxBandRadius &&
      smoothed[high + 1] >= threshold) {
    high++;
  }
  return (low, high);
}

int _luminance(Uint8List bgra, int i) =>
    (29 * bgra[i] + 150 * bgra[i + 1] + 77 * bgra[i + 2]) >> 8;

int _histogramMedian(Int32List hist, int count) {
  var sum = 0;
  for (var v = 0; v < 256; v++) {
    sum += hist[v];
    if (sum * 2 >= count) return v;
  }
  return 255;
}

int _weightedMedian(
  List<PageBackground> backgrounds,
  int Function(PageBackground) channel,
) {
  final sorted = [...backgrounds]
    ..sort((a, b) => channel(a).compareTo(channel(b)));
  final totalWeight = sorted.fold(0.0, (sum, b) => sum + b.coverage);
  var weight = 0.0;
  for (final b in sorted) {
    weight += b.coverage;
    if (weight * 2 >= totalWeight) return channel(b);
  }
  return channel(sorted.last);
}
