/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/ui/score/page_region.dart';

const _maximumDpi = 300.0;
const _maxSnapPixels = 2.0;

/// The pixels to render for a region shown at [target] device pixels. The cap
/// on the full page is raised with the enlargement, so the region is as sharp
/// as a whole page would be.
class PageRegionRender {
  final int fullWidth;
  final int fullHeight;
  final int x;
  final int y;
  final int width;
  final int height;

  const PageRegionRender({
    required this.fullWidth,
    required this.fullHeight,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory PageRegionRender.of({
    required Size pageSize,
    required Rect region,
    required Size target,
  }) {
    final scale = min(
      _maximumDpi / 72 / min(region.width, region.height),
      min(
        target.width / (pageSize.width * region.width),
        target.height / (pageSize.height * region.height),
      ),
    );
    // Even numbers keep the half size mipmap used when rendering above the device
    // resolution exactly on the device pixels. Rounding up lets the image cover
    // the box, the tolerance keeps float errors from adding two pixels.
    int evenSize(double size) => max(2, ((size - 1e-6) / 2).ceil() * 2);
    final fullWidth = evenSize(pageSize.width * scale);
    final fullHeight = evenSize(pageSize.height * scale);
    final x = (region.left * fullWidth / 2).floor() * 2;
    final y = (region.top * fullHeight / 2).floor() * 2;
    return PageRegionRender(
      fullWidth: fullWidth,
      fullHeight: fullHeight,
      x: x,
      y: y,
      width: max(2, (region.right * fullWidth / 2).ceil() * 2 - x),
      height: max(2, (region.bottom * fullHeight / 2).ceil() * 2 - y),
    );
  }

  // Whole pixels reach past the region, so this is where the image really is.
  Rect get covered => Rect.fromLTWH(
    x / fullWidth,
    y / fullHeight,
    width / fullWidth,
    height / fullHeight,
  );

  @override
  bool operator ==(Object other) =>
      other is PageRegionRender &&
      other.fullWidth == fullWidth &&
      other.fullHeight == fullHeight &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(fullWidth, fullHeight, x, y, width, height);
}

/// Shows the region of a page filling the available space.
class PdfPageImage extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final Rect region;
  final Color? backgroundColor;

  /// Laid out at the size of the full page, exactly on top of the image.
  final Widget? overlay;

  const PdfPageImage({
    super.key,
    required this.document,
    required this.pageNumber,
    this.region = fullPageRegion,
    this.backgroundColor,
    this.overlay,
  });

  @override
  State<PdfPageImage> createState() => _PdfPageImageState();
}

class _PdfPageImageState extends State<PdfPageImage> {
  ui.Image? _image;
  PageRegionRender? _imageRender;
  double _imageDevicePixelRatio = 1;
  PageRegionRender? _requested;
  PdfPageRenderCancellationToken? _cancellationToken;
  StreamSubscription<PdfDocumentEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToDocumentEvents();
  }

  @override
  void didUpdateWidget(covariant PdfPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.document != oldWidget.document ||
        widget.pageNumber != oldWidget.pageNumber) {
      _clearImage();
      _subscribeToDocumentEvents();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _cancellationToken?.cancel();
    _image?.dispose();
    super.dispose();
  }

  void _subscribeToDocumentEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = widget.document.events.listen((event) {
      if (event is PdfDocumentPageStatusChangedEvent &&
          event.changes.keys.contains(widget.pageNumber)) {
        setState(_clearImage);
      }
    });
  }

  void _clearImage() {
    _image?.dispose();
    _image = null;
    _requested = null;
    _cancellationToken?.cancel();
    _cancellationToken = null;
  }

  Future<void> _updateImage(Size target, double devicePixelRatio) async {
    final pages = widget.document.pages;
    if (target.isEmpty ||
        widget.pageNumber < 1 ||
        widget.pageNumber > pages.length) {
      return;
    }
    final page = pages[widget.pageNumber - 1];
    final request = PageRegionRender.of(
      pageSize: Size(page.width, page.height),
      region: widget.region,
      target: target,
    );
    if (request == _requested) return;
    final previous = _requested;
    _requested = request;

    _cancellationToken?.cancel();
    final token = _cancellationToken = page.createCancellationToken();
    try {
      final image = await page.renderForDisplay(
        x: request.x,
        y: request.y,
        width: request.width,
        height: request.height,
        fullWidth: request.fullWidth.toDouble(),
        fullHeight: request.fullHeight.toDouble(),
        cancellationToken: token,
      );
      if (!mounted || !identical(token, _cancellationToken)) {
        image?.dispose();
        return;
      }
      if (image == null) {
        // Otherwise the page would never try this size again.
        if (_requested == request) _requested = previous;
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
        _imageRender = request;
        _imageDevicePixelRatio = devicePixelRatio;
      });
    } catch (e, st) {
      Log.warn("Failed to render PDF page", e: e, st: st);
      // Otherwise the page would never try this size again.
      if (_requested == request) _requested = previous;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final render = _imageRender;
    final background = widget.backgroundColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        _updateImage(size * devicePixelRatio, devicePixelRatio);
        final region = widget.region;
        var fullWidth = size.width / region.width;
        var fullHeight = size.height / region.height;
        if (render != null) {
          // The rounded render size keeps one image pixel per rendered pixel, any
          // other scale would blur the page.
          final exactWidth = render.fullWidth / _imageDevicePixelRatio;
          final exactHeight = render.fullHeight / _imageDevicePixelRatio;
          if ((exactWidth - fullWidth).abs() * _imageDevicePixelRatio <=
                  _maxSnapPixels &&
              (exactHeight - fullHeight).abs() * _imageDevicePixelRatio <=
                  _maxSnapPixels) {
            fullWidth = exactWidth;
            fullHeight = exactHeight;
          }
        }
        final overlay = widget.overlay;
        return DecoratedBox(
          decoration: background != null
              ? BoxDecoration(color: background)
              : BoxDecoration(
                  color: image == null ? Colors.white : Colors.transparent,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image == null || render == null)
                const SizedBox.expand()
              else
                ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: -region.left * fullWidth,
                        top: -region.top * fullHeight,
                        width: fullWidth,
                        height: fullHeight,
                        child: _DevicePixelSnap(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                left: render.covered.left * fullWidth,
                                top: render.covered.top * fullHeight,
                                width: render.covered.width * fullWidth,
                                height: render.covered.height * fullHeight,
                                child: RawImage(image: image, fit: BoxFit.fill),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (overlay != null)
                FullPageBox(
                  region: region,
                  pageSize: Size(fullWidth, fullHeight),
                  child: _DevicePixelSnap(child: overlay),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Centered pages sit between device pixels, which blends the pixels of the
// image with their neighbors.
class _DevicePixelSnap extends SingleChildRenderObjectWidget {
  const _DevicePixelSnap({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDevicePixelSnap(View.of(context).devicePixelRatio);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDevicePixelSnap renderObject,
  ) {
    renderObject.devicePixelRatio = View.of(context).devicePixelRatio;
  }
}

class _RenderDevicePixelSnap extends RenderProxyBox {
  double _devicePixelRatio;

  _RenderDevicePixelSnap(this._devicePixelRatio);

  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final origin = MatrixUtils.transformPoint(
      getTransformTo(null),
      Offset.zero,
    );
    final snapped = (origin * _devicePixelRatio).rounded() / _devicePixelRatio;
    super.paint(context, offset + snapped - origin);
  }
}

extension on Offset {
  Offset rounded() => Offset(dx.roundToDouble(), dy.roundToDouble());
}

/// Lays out [child] at the size of the full page with only [region] showing,
/// which fills the available space.
class FullPageBox extends StatelessWidget {
  final Rect region;
  final Size? pageSize;
  final Widget child;

  const FullPageBox({
    super.key,
    required this.region,
    this.pageSize,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = pageSize?.width ?? constraints.maxWidth / region.width;
        final height =
            pageSize?.height ?? constraints.maxHeight / region.height;
        return ClipRect(
          clipBehavior: region == fullPageRegion ? Clip.none : Clip.hardEdge,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.translate(
              offset: Offset(-region.left * width, -region.top * height),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
