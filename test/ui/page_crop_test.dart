/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/score_processing/page_margins.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_surface.dart';
import 'package:sheetopia/ui/score/page_region.dart';
import 'package:sheetopia/ui/score/pdf_page_image.dart';

import 'dispose_with_tree.dart';

class _FakeRepo extends Fake implements ScoresRepository {
  @override
  Future<Map<int, List<Stroke>>> getAnnotations(String scoreId) async => {};

  @override
  Future<void> saveAnnotations(
    String scoreId,
    Map<int, List<Stroke>> pages,
  ) async {}
}

class _FakeImage implements PdfImage {
  @override
  final int width;
  @override
  final int height;
  @override
  final Uint8List pixels;

  _FakeImage(this.width, this.height) : pixels = Uint8List(width * height * 4);

  @override
  void dispose() {}
}

class _FakeToken extends Fake implements PdfPageRenderCancellationToken {
  @override
  bool isCanceled = false;

  @override
  void cancel() => isCanceled = true;
}

class _FakePage extends Fake implements PdfPage {
  final List<Map<String, num?>> renders = [];
  bool stripes = false;
  int failRenders = 0;
  late final _FakeDocument fakeDocument = _FakeDocument([this]);

  @override
  double get width => 600;

  @override
  double get height => 800;

  @override
  PdfPageRenderCancellationToken createCancellationToken() => _FakeToken();

  @override
  Future<PdfImage?> render({
    int x = 0,
    int y = 0,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    int? backgroundColor,
    PdfPageRotation? rotationOverride,
    PdfAnnotationRenderingMode annotationRenderingMode =
        PdfAnnotationRenderingMode.annotationAndForms,
    int flags = PdfPageRenderFlags.none,
    PdfPageRenderCancellationToken? cancellationToken,
    PdfPageRenderPriority? priority,
  }) async {
    renders.add({
      "x": x,
      "y": y,
      "width": width,
      "height": height,
      "fullWidth": fullWidth,
      "fullHeight": fullHeight,
    });
    if (failRenders > 0) {
      failRenders--;
      return null;
    }
    final image = _FakeImage(width!, height!);
    for (var i = 3; i < image.pixels.length; i += 4) {
      image.pixels[i] = 255;
    }
    if (stripes) {
      for (var i = 0; i < image.pixels.length; i += 4) {
        final v = (i ~/ 4) % width % 2 == 0 ? 0 : 255;
        image.pixels.fillRange(i, i + 3, v);
      }
    }
    return image;
  }
}

class _FakeDocument extends Fake implements PdfDocument {
  @override
  final List<PdfPage> pages;

  @override
  Stream<PdfDocumentEvent> get events => const Stream.empty();

  _FakeDocument(this.pages);
}

Stroke _stroke(double x, double y) => Stroke(
  colorValue: 0xFF000000,
  width: 0.001,
  points: [StrokePoint(x: x, y: y, pressure: 0.5)],
  outline: [x, y, x, y],
);

void main() {
  group("strokeInsets", () {
    test("is null without strokes", () {
      expect(strokeInsets({}), isNull);
      expect(strokeInsets({0: []}), isNull);
    });

    test("spans all pages", () {
      expect(
        strokeInsets({
          0: [_stroke(0.25, 0.5)],
          3: [_stroke(0.5, 0.125)],
        }),
        const PageMargins(left: 0.25, top: 0.125, right: 0.5, bottom: 0.5),
      );
    });
  });

  group("visiblePageRegion", () {
    const margins = PageMargins(left: 0.2, top: 0.2, right: 0.2, bottom: 0.2);
    const a4ish = Size(600, 800);

    test("crops the margin minus the padding", () {
      final region = visiblePageRegion(
        pageSize: const Size(800, 800),
        margins: margins,
        padding: 0.05,
      );
      expect(region.left, closeTo(0.15, 1e-9));
      expect(region.top, closeTo(0.15, 1e-9));
      expect(region.right, closeTo(0.85, 1e-9));
      expect(region.bottom, closeTo(0.85, 1e-9));
    });

    test("padding is the same distance on all sides", () {
      final region = visiblePageRegion(
        pageSize: a4ish,
        margins: margins,
        padding: 0.03,
      );
      final horizontal = (0.2 - region.left) * a4ish.width;
      final vertical = (0.2 - region.top) * a4ish.height;
      expect(horizontal, closeTo(vertical, 1e-9));
      expect(horizontal, closeTo(0.03 * 800, 1e-9));
    });

    test("padding larger than the margin shows the whole page", () {
      expect(
        visiblePageRegion(pageSize: a4ish, margins: margins, padding: 1),
        fullPageRegion,
      );
    });

    test("keeps the strokes visible", () {
      final region = visiblePageRegion(
        pageSize: const Size(800, 800),
        margins: margins,
        padding: 0.05,
        strokes: const PageMargins(left: 0.1, top: 0.5, right: 0, bottom: 0.5),
      );
      expect(region.left, closeTo(0.1, 1e-9));
      expect(region.top, closeTo(0.15, 1e-9));
      expect(region.right, closeTo(1, 1e-9));
      expect(region.bottom, closeTo(0.85, 1e-9));
    });

    test("a stroke in the padding does not grow the region", () {
      final first = visiblePageRegion(
        pageSize: const Size(800, 800),
        margins: margins,
        padding: 0.05,
      );
      final second = visiblePageRegion(
        pageSize: const Size(800, 800),
        margins: margins,
        padding: 0.05,
        strokes: PageMargins(
          left: first.left,
          top: first.top,
          right: 1 - first.right,
          bottom: 1 - first.bottom,
        ),
      );
      expect(second, first);
    });
  });

  group("PageRegionRender", () {
    const pageSize = Size(600, 800);

    test("renders a whole page like a page view would", () {
      final render = PageRegionRender.of(
        pageSize: pageSize,
        region: fullPageRegion,
        target: const Size(1200, 1600),
      );
      expect(render.fullWidth, 1200);
      expect(render.fullHeight, 1600);
      expect(render.x, 0);
      expect(render.y, 0);
      expect(render.width, 1200);
      expect(render.height, 1600);
    });

    test("only renders the region, at the resolution of the target", () {
      final render = PageRegionRender.of(
        pageSize: pageSize,
        region: const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        target: const Size(1200, 1600),
      );
      expect(render.fullWidth, 2400);
      expect(render.fullHeight, 3200);
      expect(render.x, 600);
      expect(render.y, 800);
      expect(render.width, 1200);
      expect(render.height, 1600);
    });

    test("the cap gives a region as many pixels as a whole page", () {
      const huge = Size(100000, 100000);
      final whole = PageRegionRender.of(
        pageSize: pageSize,
        region: fullPageRegion,
        target: huge,
      );
      final half = PageRegionRender.of(
        pageSize: pageSize,
        region: const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75),
        target: huge,
      );
      expect(half.width, closeTo(whole.width, 3));
      expect(half.height, closeTo(whole.height, 3));
    });

    test("only uses even pixel sizes and offsets", () {
      final render = PageRegionRender.of(
        pageSize: pageSize,
        region: const Rect.fromLTRB(0.1234, 0.2345, 0.8765, 0.7654),
        target: const Size(777, 1033),
      );
      for (final value in [
        render.fullWidth,
        render.fullHeight,
        render.x,
        render.y,
        render.width,
        render.height,
      ]) {
        expect(value.isEven, isTrue);
      }
    });

    test("covers at least the region with whole pixels", () {
      const region = Rect.fromLTRB(0.1234, 0.2345, 0.8765, 0.7654);
      final covered = PageRegionRender.of(
        pageSize: pageSize,
        region: region,
        target: const Size(777, 1033),
      ).covered;
      expect(covered.left, lessThanOrEqualTo(region.left));
      expect(covered.top, lessThanOrEqualTo(region.top));
      expect(covered.right, greaterThanOrEqualTo(region.right));
      expect(covered.bottom, greaterThanOrEqualTo(region.bottom));
      expect(covered.width - region.width, lessThan(4 / 777));
    });
  });

  group("PdfPageImage", () {
    const region = Rect.fromLTRB(0.1, 0.1, 0.9, 0.9);

    Future<void> pump(
      WidgetTester tester,
      _FakePage page, {
      Rect region = fullPageRegion,
      Size size = const Size(300, 400),
    }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: PdfPageImage(
                  document: page.fakeDocument,
                  pageNumber: 1,
                  region: region,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    testWidgets("renders only the region", (tester) async {
      final page = _FakePage();
      await pump(tester, page, region: region);
      expect(page.renders.single, {
        "x": 74,
        "y": 100,
        "width": 602,
        "height": 800,
        "fullWidth": 750.0,
        "fullHeight": 1000.0,
      });
      await settle(tester);
    });

    testWidgets("tries a size again after a failed render", (tester) async {
      final page = _FakePage()..failRenders = 1;
      await pump(tester, page, region: region);
      await settle(tester);
      expect(page.renders, hasLength(1));

      await pump(tester, page, region: region);
      await settle(tester);
      expect(page.renders, hasLength(2));
    });

    testWidgets("the overlay shares the size of the rendered page", (
      tester,
    ) async {
      final page = _FakePage();
      const overlayKey = Key("overlay");
      const size = Size(300.3, 400.3);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: PdfPageImage(
                  document: page.fakeDocument,
                  pageNumber: 1,
                  region: region,
                  overlay: const SizedBox.expand(key: overlayKey),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      final image = tester.getRect(find.byType(RawImage));
      final overlay = tester.getRect(find.byKey(overlayKey));
      final render = PageRegionRender.of(
        pageSize: Size(page.width, page.height),
        region: region,
        target: size * 2,
      );
      expect(overlay.width, render.fullWidth / 2);
      expect(overlay.height, render.fullHeight / 2);
      expect(overlay.width, isNot(closeTo(size.width / region.width, 1e-6)));
      expect(
        image.left - overlay.left,
        closeTo(render.covered.left * overlay.width, 1e-6),
      );
      expect(
        image.top - overlay.top,
        closeTo(render.covered.top * overlay.height, 1e-6),
      );
    });

    testWidgets("places the rendered pixels on the region", (tester) async {
      final page = _FakePage();
      await pump(tester, page, region: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.7));
      await settle(tester);

      final rect = tester.getRect(find.byType(RawImage));
      final origin = tester.getTopLeft(find.byType(PdfPageImage));
      expect(rect.left - origin.dx, closeTo(0, 0.5));
      expect(rect.top - origin.dy, closeTo(0, 0.5));
      expect(rect.width, closeTo(300, 1));
      expect(rect.height, closeTo(400, 1));
    });

    testWidgets("keeps one image pixel per device pixel between pixels", (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final page = _FakePage()..stripes = true;
      final key = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.25, top: 0.25),
                  child: SizedBox(
                    width: 60.3,
                    height: 80.3,
                    child: PdfPageImage(
                      document: page.fakeDocument,
                      pageNumber: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        final row = image.height ~/ 2 * image.width * 4;
        for (var x = 8; x < image.width - 8; x++) {
          expect(bytes[row + x * 4], anyOf(0, 255), reason: "x $x");
        }
      });
    });

    testWidgets("rounding keeps one image pixel per device pixel and covers", (
      tester,
    ) async {
      final page = _FakePage();
      await pump(tester, page, size: const Size(299.45, 399.27));
      await settle(tester);

      expect(page.renders.single["fullWidth"], 600.0);
      expect(page.renders.single["fullHeight"], 800.0);
      final rect = tester.getRect(find.byType(RawImage));
      expect(rect.width, 300);
      expect(rect.height, 400);
    });

    testWidgets("an image limited by the cap still fills the box", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(2000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const size = Size(1261.5, 1682);
      final page = _FakePage();
      await pump(tester, page, size: size);
      await settle(tester);

      expect(page.renders.single["fullHeight"], 3334.0);
      final rect = tester.getRect(find.byType(RawImage));
      expect(rect.width, closeTo(size.width, 1e-6));
      expect(rect.height, closeTo(size.height, 1e-6));
    });

    testWidgets("only renders again when the pixels change", (tester) async {
      final page = _FakePage();
      await pump(tester, page);
      await settle(tester);
      await pump(tester, page);
      await settle(tester);
      expect(page.renders, hasLength(1));

      await pump(tester, page, size: const Size(150, 200));
      await settle(tester);
      expect(page.renders, hasLength(2));
    });

    testWidgets("keeps the shadow unless there is a background", (
      tester,
    ) async {
      final page = _FakePage();
      await pump(tester, page, region: region);
      await settle(tester);
      final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      expect((box.decoration as BoxDecoration).boxShadow, isNotEmpty);
    });
  });

  group("annotating a cropped page", () {
    const region = Rect.fromLTRB(0.2, 0.1, 0.8, 0.9);
    const window = Size(300, 400);
    late AnnotateViewModel viewModel;
    late bool disposed;

    setUp(() {
      viewModel = AnnotateViewModel(repo: _FakeRepo(), scoreId: "a", pages: {});
      viewModel.pageBounds = (_) => region;
      disposed = false;
    });

    void disposeViewModel() {
      if (disposed) return;
      disposed = true;
      viewModel.dispose();
    }

    tearDown(disposeViewModel);

    Future<Offset> pump(WidgetTester tester, Rect region) async {
      await tester.pumpWidget(
        DisposeWithTree(
          onDispose: disposeViewModel,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.fromSize(
                size: window,
                child: FullPageBox(
                  region: region,
                  child: AnnotationSurface(
                    viewModel: viewModel,
                    pageIndex: 0,
                    visibleRegion: region,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getTopLeft(find.byType(FullPageBox));
    }

    Future<StrokePoint> draw(
      WidgetTester tester,
      Offset from,
      Offset to,
    ) async {
      final gesture = await tester.startGesture(
        from,
        kind: PointerDeviceKind.stylus,
      );
      await gesture.moveTo(to);
      await gesture.moveTo(to);
      await gesture.up();
      await tester.pump();
      return viewModel.strokesFor(0).last.points.first;
    }

    testWidgets("a point lands on the same spot of the full page", (
      tester,
    ) async {
      final origin = await pump(tester, region);
      final point = await draw(
        tester,
        origin + const Offset(150, 100),
        origin + const Offset(160, 110),
      );
      expect(point.x, closeTo(0.2 + 150 / 300 * 0.6, 1e-3));
      expect(point.y, closeTo(0.1 + 100 / 400 * 0.8, 1e-3));
    });

    testWidgets("uses the full page without a crop", (tester) async {
      final origin = await pump(tester, fullPageRegion);
      final point = await draw(
        tester,
        origin + const Offset(150, 100),
        origin + const Offset(160, 110),
      );
      expect(point.x, closeTo(0.5, 1e-3));
      expect(point.y, closeTo(0.25, 1e-3));
    });

    testWidgets("drawing past the edge stays in the visible part", (
      tester,
    ) async {
      final origin = await pump(tester, region);
      final gesture = await tester.startGesture(
        origin + const Offset(290, 390),
        kind: PointerDeviceKind.stylus,
      );
      for (var i = 1; i <= 8; i++) {
        await gesture.moveTo(origin + Offset(290.0 + i * 40, 390.0 + i * 40));
      }
      await gesture.up();
      await tester.pump();

      final stroke = viewModel.strokesFor(0).single;
      for (final point in stroke.points) {
        expect(point.x, lessThanOrEqualTo(region.right));
        expect(point.y, lessThanOrEqualTo(region.bottom));
      }
    });
  });
}
