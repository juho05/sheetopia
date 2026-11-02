/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/services/score_processing/background_color.dart';
import 'package:sheetopia/data/services/score_processing/page_margins.dart';

const _width = 500;
const _height = 700;

PageBitmap _page(
  bool Function(int x, int y) isInk, {
  int paper = 255,
  int ink = 0,
}) {
  final bgra = Uint8List(_width * _height * 4);
  for (var y = 0; y < _height; y++) {
    for (var x = 0; x < _width; x++) {
      final v = isInk(x, y) ? ink : paper;
      final i = (y * _width + x) * 4;
      bgra[i] = v;
      bgra[i + 1] = v;
      bgra[i + 2] = v;
      bgra[i + 3] = 255;
    }
  }
  return PageBitmap(width: _width, height: _height, bgra: bgra);
}

PageMargins? _estimate(PageBitmap page) =>
    estimatePageMargins(page, estimatePageBackground(page));

// Staff lines in a frame, sparse like real notation. A solid block would be
// larger than the paper and taken for the background.
bool _frame(int x, int y, int left, int top, int right, int bottom) {
  if (x < left || x >= right || y < top || y >= bottom) return false;
  return x == left ||
      x == right - 1 ||
      y == top ||
      y == bottom - 1 ||
      y % 20 < 2;
}

bool _content(int x, int y) => _frame(x, y, 50, 70, 450, 630);

void _expectMargins(
  PageMargins? margins, {
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  expect(margins, isNotNull);
  expect(margins!.left, closeTo(left, 0.001), reason: "left");
  expect(margins.top, closeTo(top, 0.001), reason: "top");
  expect(margins.right, closeTo(right, 0.001), reason: "right");
  expect(margins.bottom, closeTo(bottom, 0.001), reason: "bottom");
}

void main() {
  group("estimatePageMargins", () {
    test("measures the distance to the content", () {
      _expectMargins(
        _estimate(_page(_content)),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("measures each side on its own", () {
      _expectMargins(
        _estimate(_page((x, y) => _frame(x, y, 25, 35, 400, 350))),
        left: 0.05,
        top: 0.05,
        right: 0.2,
        bottom: 0.5,
      );
    });

    test("finds faint content on clean paper", () {
      _expectMargins(
        _estimate(_page(_content, ink: 210)),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("finds faint content next to a few dark pixels", () {
      final page = _page(_content, ink: 210);
      for (var i = 0; i < 40; i++) {
        final p = ((200 + i) * _width + 200) * 4;
        page.bgra.fillRange(p, p + 3, 170);
      }
      _expectMargins(
        _estimate(page),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("ignores dust", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || (x == 5 && y == 5))),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("ignores paper grain", () {
      final page = _page(_content, paper: 230);
      for (var i = 0; i < page.bgra.length; i += 4) {
        final grain = (i * 2654435761 >> 8) % 16;
        if (page.bgra[i] == 0) continue;
        page.bgra[i] += grain;
        page.bgra[i + 1] += grain;
        page.bgra[i + 2] += grain;
      }
      _expectMargins(
        _estimate(page),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("recognizes a blank page", () {
      expect(_estimate(_page((x, y) => false)), PageMargins.blank);
    });

    test("treats a page with only an edge band as blank", () {
      expect(_estimate(_page((x, y) => x < 4)), PageMargins.blank);
      expect(_estimate(_page((x, y) => x < 4 || y < 4)), PageMargins.blank);
    });

    test("is undetermined if only one axis has content", () {
      expect(_estimate(_page((x, y) => y == 300 && x % 4 == 0)), isNull);
    });

    test("is undetermined without a dominant background", () {
      final page = _page(_content);
      const scattered = PageBackground(
        r: 0,
        g: 0,
        b: 0,
        coverage: 0.01,
        paperLow: 0,
        paperHigh: 255,
        paperCoverage: 1,
        paperTruncated: false,
      );
      expect(estimatePageMargins(page, scattered), isNull);
      expect(estimatePageMargins(page, null), isNull);
    });

    test("is undetermined if too little of the page is paper", () {
      const dense = PageBackground(
        r: 255,
        g: 255,
        b: 255,
        coverage: 1,
        paperLow: 251,
        paperHigh: 255,
        paperCoverage: 0.5,
        paperTruncated: false,
      );
      expect(estimatePageMargins(_page(_content), dense), isNull);
    });

    test("is undetermined if faint content may hide in the paper range", () {
      const truncated = PageBackground(
        r: 255,
        g: 255,
        b: 255,
        coverage: 1,
        paperLow: 150,
        paperHigh: 255,
        paperCoverage: 1,
        paperTruncated: true,
      );
      expect(estimatePageMargins(_page((x, y) => false), truncated), isNull);
    });

    group("on a noisy scan", () {
      int noise(int x, int y) => (x * 7919 + y * 104729) * 2654435761 >> 8;
      int paper(int x, int y) => 195 + 45 * x ~/ _width + noise(x, y) % 9 - 4;
      bool block(int x, int y) =>
          x >= 50 &&
          x < 450 &&
          y >= 70 &&
          y < 630 &&
          ((y - 70) % 12 < 4 || y >= 626);

      PageBitmap scan(int Function(int x, int y) luminance) {
        final bgra = Uint8List(_width * _height * 4);
        for (var y = 0; y < _height; y++) {
          for (var x = 0; x < _width; x++) {
            final i = (y * _width + x) * 4;
            bgra.fillRange(i, i + 3, luminance(x, y));
            bgra[i + 3] = 255;
          }
        }
        return PageBitmap(width: _width, height: _height, bgra: bgra);
      }

      test("gray ink does not join the paper range", () {
        final page = scan(
          (x, y) => block(x, y) ? 110 + noise(x, y) % 81 : paper(x, y),
        );
        expect(estimatePageBackground(page)!.paperLow, greaterThan(150));
        _expectMargins(
          _estimate(page),
          left: 0.1,
          top: 0.1,
          right: 0.1,
          bottom: 0.1,
        );
      });

      test("faint outer content is not cut", () {
        final page = scan((x, y) {
          final core = x >= 150 && x < 350 && y >= 200 && y < 500;
          if (core && (y - 70) % 12 < 2) return noise(x, y) % 30;
          return block(x, y) ? 120 + noise(x, y) % 71 : paper(x, y);
        });
        _expectMargins(
          _estimate(page),
          left: 0.1,
          top: 0.1,
          right: 0.1,
          bottom: 0.1,
        );
      });

      test("a strong gradient is undetermined instead of cut", () {
        for (final (from, ink) in [(0, 0), (100, 90)]) {
          final page = scan(
            (x, y) => _content(x, y) ? ink : from + (255 - from) * y ~/ _height,
          );
          expect(_estimate(page), isNull);
        }
      });
    });

    test("has no margin where the content reaches the edge", () {
      final margins = _estimate(_page((x, y) => _frame(x, y, 0, 70, 500, 630)));
      expect(margins!.left, 0);
      expect(margins.right, 0);
    });

    test("skips a thin band at the edge", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || x < 5)),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("skips thin bands on two neighboring edges", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || x < 5 || y < 5)),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("skips a band covering only a part of the edge", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || (x < 2 && y < 300))),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("skips a tapering band with a blob in the corner", () {
      bool shadow(int x, int y) {
        final fromBottom = _height - 1 - y;
        return fromBottom < 2 ||
            (fromBottom < 6 && x >= _width - 16) ||
            (fromBottom == 2 && x < 70);
      }

      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || shadow(x, y))),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("skips a band with a small hole", () {
      _expectMargins(
        _estimate(
          _page((x, y) => _content(x, y) || x < 2 || (x == 3 && y < 100)),
        ),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("keeps content running off the edge", () {
      final margins = _estimate(
        _page((x, y) => _frame(x, y, 0, 70, 500, 630) || y < 4),
      );
      expect(margins!.left, 0);
      expect(margins.right, 0);
      expect(margins.top, closeTo(0.1, 0.001));
    });

    test("keeps a thick band at the edge", () {
      expect(_estimate(_page((x, y) => _content(x, y) || x < 30))!.left, 0);
    });

    test("keeps a thin band without clean paper after it", () {
      final margins = _estimate(
        _page((x, y) => _frame(x, y, 6, 70, 450, 630) || x < 5),
      );
      expect(margins!.left, 0);
    });
  });

  group("estimatePageMargins with marks on one axis", () {
    bool shortContent(int x, int y) => _frame(x, y, 50, 70, 450, 350);

    test("a vertical tick above the content limits the top", () {
      _expectMargins(
        _estimate(
          _page((x, y) => _content(x, y) || (x == 250 && y >= 30 && y < 36)),
        ),
        left: 0.1,
        top: 30 / 700,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("a horizontal dash beside the content limits the left", () {
      _expectMargins(
        _estimate(
          _page((x, y) => _content(x, y) || (y == 300 && x >= 20 && x < 26)),
        ),
        left: 20 / 500,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("a tick that sets the left margin also limits the bottom", () {
      _expectMargins(
        _estimate(
          _page(
            (x, y) => shortContent(x, y) || (x == 25 && y >= 500 && y < 508),
          ),
        ),
        left: 25 / 500,
        top: 0.1,
        right: 0.1,
        bottom: 192 / 700,
      );
    });

    test("a diagonal stroke counts for both axes", () {
      _expectMargins(
        _estimate(
          _page(
            (x, y) => _content(x, y) || (y >= 30 && y < 36 && x == y + 200),
          ),
        ),
        left: 0.1,
        top: 30 / 700,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("small specks do not count", () {
      _expectMargins(
        _estimate(
          _page(
            (x, y) =>
                _content(x, y) ||
                (x == 250 && y == 30) ||
                (x >= 20 && x < 22 && y >= 300 && y < 302),
          ),
        ),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });

    test("a dirt line through the whole page keeps the other axis", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || x == 480)),
        left: 0.1,
        top: 0.1,
        right: 19 / 500,
        bottom: 0.1,
      );
    });

    test("a tapering scan edge keeps the other axis", () {
      _expectMargins(
        _estimate(_page((x, y) => _content(x, y) || x < 6 - y ~/ 120)),
        left: 0.1,
        top: 0.1,
        right: 0.1,
        bottom: 0.1,
      );
    });
  });

  group("combinePageMargins", () {
    const a = PageMargins(left: 0.1, top: 0.2, right: 0.05, bottom: 0.4);
    const b = PageMargins(left: 0.2, top: 0.1, right: 0.15, bottom: 0.05);

    test("takes the smallest margin of every side", () {
      expect(
        combinePageMargins([a, b]),
        const PageMargins(left: 0.1, top: 0.1, right: 0.05, bottom: 0.05),
      );
    });

    test("returns null without pages", () {
      expect(combinePageMargins([]), isNull);
    });

    test("one undetermined page makes the whole score undetermined", () {
      expect(combinePageMargins([a, null, b]), isNull);
    });

    test("blank pages do not limit the other pages", () {
      expect(combinePageMargins([b, PageMargins.blank]), b);
    });

    test("returns null if all pages are blank", () {
      expect(combinePageMargins([PageMargins.blank]), isNull);
    });

    test("allows one large margin", () {
      const page = PageMargins(left: 0, top: 0.05, right: 0, bottom: 0.45);
      expect(combinePageMargins([page]), page);
    });

    test("a half-empty page does not count as a mis-detection", () {
      const full = PageMargins(left: 0.1, top: 0.1, right: 0.1, bottom: 0.1);
      const half = PageMargins(left: 0.1, top: 0.1, right: 0.1, bottom: 0.6);
      expect(combinePageMargins([full, half]), full);
    });

    test("large margins on opposite sides are a mis-detection", () {
      expect(
        combinePageMargins([
          const PageMargins(left: 0, top: 0.26, right: 0, bottom: 0.3),
        ]),
        isNull,
      );
      expect(
        combinePageMargins([
          const PageMargins(left: 0.3, top: 0, right: 0.26, bottom: 0),
        ]),
        isNull,
      );
    });

    test("opposite sides of exactly a quarter are allowed", () {
      const page = PageMargins(left: 0, top: 0.25, right: 0, bottom: 0.25);
      expect(combinePageMargins([page]), page);
    });

    test("a large margin is limited to keep half of the axis", () {
      expect(
        combinePageMargins([
          const PageMargins(left: 0.1, top: 0.07, right: 0.05, bottom: 0.6),
        ]),
        PageMargins(left: 0.1, top: 0.07, right: 0.05, bottom: 0.5 - 0.07),
      );
      expect(
        combinePageMargins([
          const PageMargins(left: 0.6, top: 0.1, right: 0.05, bottom: 0.1),
        ]),
        PageMargins(left: 0.5 - 0.05, top: 0.1, right: 0.05, bottom: 0.1),
      );
    });

    test("limits after taking the smallest margins", () {
      const full = PageMargins(left: 0.1, top: 0.1, right: 0.1, bottom: 0.3);
      const half = PageMargins(left: 0.1, top: 0.1, right: 0.1, bottom: 0.7);
      expect(combinePageMargins([full, half]), full);
    });
  });
}
