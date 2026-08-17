/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:ui' show Offset, Path;

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/lasso.dart';
import 'package:sheetopia/ui/annotate/stroke_outline.dart';

enum AnnotateTool { pen, eraser, lasso }

sealed class _UndoOp {
  final int pageIndex;

  const _UndoOp({required this.pageIndex});
}

class _AddOp extends _UndoOp {
  final List<Stroke> strokes;

  const _AddOp({required super.pageIndex, required this.strokes});
}

class _EraseOp extends _UndoOp {
  // (index in the pre-erase snapshot, stroke), ascending by index.
  final List<(int, Stroke)> removed;

  const _EraseOp({required super.pageIndex, required this.removed});
}

class _MoveOp extends _UndoOp {
  // (index in the page list, stroke before the move, stroke after it).
  final List<(int, Stroke, Stroke)> moved;

  const _MoveOp({required super.pageIndex, required this.moved});
}

class _Selection {
  final int pageIndex;

  // Positions in _pages[pageIndex], ascending, and the instances at them.
  final List<int> indices;
  final List<Stroke> strokes;

  // Handed to AnnotationPainter, which compares it by identity, so a fresh
  // instance per selection change is what makes the static layer repaint.
  final Set<Stroke> hidden;

  // The closed lasso, normalized. Never mutated, so the painter can cache the
  // dashed marquee it builds from it.
  final List<double> polygon;

  // How far the strokes may travel before they would leave the page.
  final ({double minDx, double maxDx, double minDy, double maxDy}) dragLimits;

  _Selection({
    required this.pageIndex,
    required this.indices,
    required this.strokes,
    required this.polygon,
  }) : hidden = Set<Stroke>.identity()..addAll(strokes),
       dragLimits = _limitsFor(strokes);

  bool contains(double x, double y, Offset offset) =>
      pointInPolygon(polygon, x - offset.dx, y - offset.dy);

  Offset clampDrag(Offset offset) => Offset(
    offset.dx.clamp(dragLimits.minDx, dragLimits.maxDx),
    offset.dy.clamp(dragLimits.minDy, dragLimits.maxDy),
  );

  // Measured on the outlines, which is what actually gets painted. A selection
  // larger than the page in an axis inverts the two bounds, and the min/max
  // pair then lets it slide between the edges instead of pinning it.
  static ({double minDx, double maxDx, double minDy, double maxDy}) _limitsFor(
    List<Stroke> strokes,
  ) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final stroke in strokes) {
      final outline = stroke.outline;
      for (var i = 0; i + 1 < outline.length; i += 2) {
        minX = min(minX, outline[i]);
        minY = min(minY, outline[i + 1]);
        maxX = max(maxX, outline[i]);
        maxY = max(maxY, outline[i + 1]);
      }
    }
    if (!minX.isFinite) {
      return (
        minDx: double.negativeInfinity,
        maxDx: double.infinity,
        minDy: double.negativeInfinity,
        maxDy: double.infinity,
      );
    }
    return (
      minDx: min(-minX, 1 - maxX),
      maxDx: max(-minX, 1 - maxX),
      minDy: min(-minY, 1 - maxY),
      maxDy: max(-minY, 1 - maxY),
    );
  }
}

class _Clipboard {
  final List<Stroke> strokes;

  // Aspect of the source page, null when the layout could not be resolved.
  final double? aspect;

  // Copies of these strokes each page already holds, so repeated pastes
  // cascade instead of landing invisibly on top of each other.
  final Map<int, int> copies;

  _Clipboard({
    required this.strokes,
    required this.aspect,
    required this.copies,
  });
}

// Fires on every in-progress input sample so only the layer that sample
// touches repaints, without rebuilding the widget tree or the static
// (committed) strokes layer.
class _Notifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

class AnnotateViewModel extends ChangeNotifier {
  static const int red = 0xFFFF0000;
  static const int blue = 0xFF2196F3;
  static const int green = 0xFF4CAF50;
  static const int highlighterYellow = 0x88FFEB3B;

  static const List<int> palette = [red, blue, green, highlighterYellow];

  static const double minWidth = 0.0008;
  static const double maxWidth = 0.05;

  static const double _streamline = 0.1;
  static const double _streamlineT = 0.15 + (1 - _streamline) * 0.85;

  static const double _smoothing = 0.05;

  // Lasso samples closer than this to the last kept one are dropped. No
  // streamlining: the marquee should track the pointer instead of lagging it.
  static const double _lassoMinD = 0.002;

  // A lasso whose bounding box stays below this in both axes is a tap.
  static const double _lassoMinSpan = 0.005;

  static const double _pasteNudge = 0.005;

  final ScoresRepository _repo;
  final String _scoreId;

  final Map<int, List<Stroke>> _pages = {};
  bool _dirty = false;

  // Two channels so a pen sample never dirties the lasso layer and a lasso
  // sample never dirties the live-stroke layer.
  final Map<int, _Notifier> _liveRepaints = {};
  final Map<int, _Notifier> _lassoRepaints = {};

  Listenable liveRepaintFor(int pageIndex) =>
      _liveRepaints.putIfAbsent(pageIndex, _Notifier.new);

  Listenable lassoRepaintFor(int pageIndex) =>
      _lassoRepaints.putIfAbsent(pageIndex, _Notifier.new);

  void _pingLive(int? pageIndex) {
    if (pageIndex != null) _liveRepaints[pageIndex]?.ping();
  }

  void _pingLasso(int? pageIndex) {
    if (pageIndex != null) _lassoRepaints[pageIndex]?.ping();
  }

  final List<_UndoOp> _undoStack = [];
  final List<_UndoOp> _redoStack = [];

  int _colorValue = red;

  int get colorValue => _colorValue;

  AnnotateTool _tool = AnnotateTool.pen;

  AnnotateTool get tool => _tool;

  bool get eraser => _tool == AnnotateTool.eraser;

  bool get lasso => _tool == AnnotateTool.lasso;

  double _width = 0.004;

  double get width => _width;

  bool _drawMode =
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool get drawMode => _drawMode;

  int? _activePageIndex;
  bool _activeIsTouch = false;
  List<StrokePoint>? _activePoints;
  StrokePoint? _lastRawPoint;
  double _sx = 0;
  double _sy = 0;

  Path? _livePath;

  List<Stroke>? _eraseSnapshot;
  List<(int, Stroke)>? _erasePending;
  StrokePoint? _lastErasePoint;
  double _eraseAspect = 1.0;
  double _drawAspect = 1.0;

  _Selection? _selection;
  _Clipboard? _clipboard;

  // The live drag delta, normalized, on top of the selection's own geometry.
  // The surface feeds it to a Transform above a RepaintBoundary, so a drag
  // moves a cached layer instead of repainting the selected strokes.
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);

  ValueListenable<Offset> get dragOffset => _dragOffset;

  // Flat normalized x/y pairs of the lasso being drawn right now.
  List<double>? _lassoPoints;
  double? _dragStartX;
  double? _dragStartY;

  // Resolves a page's height / width, for the cross-page paste. Set by
  // AnnotatePage, which owns the pdfrx controller; null until it is ready.
  double? Function(int pageIndex)? pageAspect;

  AnnotateViewModel({required ScoresRepository repo, required String scoreId})
    : _repo = repo,
      _scoreId = scoreId {
    _load();
  }

  Future<void> _load() async {
    _pages.addAll(await _repo.getAnnotations(_scoreId));
    notifyListeners();
  }

  void setColor(int color) {
    _colorValue = color;
    _setTool(AnnotateTool.pen);
  }

  void setEraser() => _setTool(AnnotateTool.eraser);

  void setLasso() => _setTool(AnnotateTool.lasso);

  void _setTool(AnnotateTool tool) {
    if (_tool != tool) {
      _tool = tool;
      _resetLasso();
    }
    notifyListeners();
  }

  // Drops the selection and any in-progress capture or drag. Silent: the
  // callers all notify themselves.
  void _resetLasso() {
    final pageIndex = _selection?.pageIndex ?? _activePageIndex;
    _selection = null;
    _dragOffset.value = Offset.zero;
    _lassoPoints = null;
    _dragStartX = null;
    _dragStartY = null;
    _pingLasso(pageIndex);
  }

  bool get hasSelection => _selection != null;

  bool get canPaste => _clipboard != null;

  void clearSelection() {
    if (_selection == null && _lassoPoints == null) return;
    _resetLasso();
    notifyListeners();
  }

  double get widthFraction =>
      (log(_width / minWidth) / log(maxWidth / minWidth)).clamp(0.0, 1.0);

  void setWidthFraction(double t) {
    _width = minWidth * pow(maxWidth / minWidth, t.clamp(0.0, 1.0));
    notifyListeners();
  }

  void toggleDrawMode() {
    _drawMode = !_drawMode;
    notifyListeners();
  }

  List<Stroke> strokesFor(int pageIndex) => _pages[pageIndex] ?? const [];

  // The selected strokes, which the static layer must skip because the
  // selection layer draws them under the live drag offset.
  Set<Stroke>? selectionStrokesFor(int pageIndex) {
    final selection = _selection;
    return selection != null && selection.pageIndex == pageIndex
        ? selection.hidden
        : null;
  }

  ({List<Stroke> strokes, List<double> polygon})? selectionFor(int pageIndex) {
    final selection = _selection;
    if (selection == null || selection.pageIndex != pageIndex) return null;
    return (strokes: selection.strokes, polygon: selection.polygon);
  }

  List<double>? lassoPointsFor(int pageIndex) =>
      _activePageIndex == pageIndex ? _lassoPoints : null;

  StrokePoint? eraserCursorFor(int pageIndex) {
    if (_activePageIndex != pageIndex || _eraseSnapshot == null) return null;
    return _lastErasePoint;
  }

  // Geometry is in page-width units. The painter scales it by size.width.
  ({
    int colorValue,
    double width,
    double aspect,
    Path path,
    Offset lastKept,
    Offset tip,
    bool isDot,
  })?
  liveStrokeFor(int pageIndex) {
    final path = _livePath;
    final points = _activePoints;
    if (_activePageIndex != pageIndex || path == null || points == null) {
      return null;
    }
    final last = points.last;
    final raw = _lastRawPoint ?? last;
    return (
      colorValue: _colorValue,
      width: _width,
      aspect: _drawAspect,
      path: path,
      lastKept: Offset(last.x, last.y * _drawAspect),
      tip: Offset(raw.x, raw.y * _drawAspect),
      isDot: points.length == 1,
    );
  }

  void startStroke(
    int pageIndex,
    StrokePoint p,
    double aspect, {
    bool isTouch = false,
  }) {
    _activePageIndex = pageIndex;
    _activeIsTouch = isTouch;
    if (_tool == AnnotateTool.lasso) {
      _startLasso(pageIndex, p);
      return;
    }
    if (eraser) {
      _eraseSnapshot = List.of(_pages[pageIndex] ?? const <Stroke>[]);
      _erasePending = [];
      _lastErasePoint = p;
      _eraseAspect = aspect;
      _eraseSegment(p, p);
      notifyListeners();
      return;
    }
    _drawAspect = aspect;
    _activePoints = [p];
    _lastRawPoint = p;
    _sx = p.x;
    _sy = p.y;
    _livePath = Path()..moveTo(p.x, p.y * aspect);
    _pingLive(pageIndex);
  }

  void _startLasso(int pageIndex, StrokePoint p) {
    final selection = _selection;
    if (selection != null &&
        selection.pageIndex == pageIndex &&
        selection.contains(p.x, p.y, _dragOffset.value)) {
      _dragStartX = p.x;
      _dragStartY = p.y;
      return;
    }
    _lassoPoints = [p.x, p.y];
    if (selection != null) {
      _selection = null;
      _dragOffset.value = Offset.zero;
      notifyListeners();
    }
    _pingLasso(pageIndex);
  }

  void appendPoint(StrokePoint p, double aspect) {
    if (_tool == AnnotateTool.lasso) {
      _appendLasso(p, aspect);
      return;
    }
    if (_eraseSnapshot != null) {
      final last = _lastErasePoint ?? p;
      _lastErasePoint = p;
      _eraseAspect = aspect;
      _eraseSegment(last, p);
      notifyListeners();
      return;
    }
    final points = _activePoints;
    if (points == null) return;
    _drawAspect = aspect;
    _lastRawPoint = p;
    _sx += (p.x - _sx) * _streamlineT;
    _sy += (p.y - _sy) * _streamlineT;
    final last = points.last;
    final minD = _width * _smoothing * max(1.0, aspect);
    final dx = _sx - last.x;
    final dy = (_sy - last.y) * aspect;
    if (dx * dx + dy * dy > minD * minD) {
      points.add(StrokePoint(x: _sx, y: _sy, pressure: p.pressure));
      _livePath?.lineTo(_sx, _sy * aspect);
    }
    _pingLive(_activePageIndex);
  }

  void _appendLasso(StrokePoint p, double aspect) {
    final startX = _dragStartX;
    final startY = _dragStartY;
    final selection = _selection;
    if (startX != null && startY != null && selection != null) {
      // No repaint: the surface moves the already-rasterized selection layer.
      _dragOffset.value = selection.clampDrag(
        Offset(p.x - startX, p.y - startY),
      );
      return;
    }
    final points = _lassoPoints;
    if (points == null) return;
    final dx = p.x - points[points.length - 2];
    final dy = (p.y - points[points.length - 1]) * aspect;
    // A dropped sample would repaint the identical marquee, so only a kept one
    // is worth a ping.
    if (dx * dx + dy * dy > _lassoMinD * _lassoMinD) {
      points
        ..add(p.x)
        ..add(p.y);
      _pingLasso(_activePageIndex);
    }
  }

  void endStroke() {
    if (_tool == AnnotateTool.lasso) {
      _endLasso();
      return;
    }
    final pageIndex = _activePageIndex;
    final points = _activePoints;
    final tip = _lastRawPoint;
    final erased = _erasePending;
    _activePageIndex = null;
    _activeIsTouch = false;
    _activePoints = null;
    _lastRawPoint = null;
    _livePath = null;
    _eraseSnapshot = null;
    _erasePending = null;
    _lastErasePoint = null;
    _pingLive(pageIndex);

    if (erased != null) {
      if (pageIndex != null && erased.isNotEmpty) {
        erased.sort((a, b) => a.$1.compareTo(b.$1));
        _undoStack.add(_EraseOp(pageIndex: pageIndex, removed: erased));
        _redoStack.clear();
      }
      notifyListeners();
      return;
    }

    if (pageIndex == null || points == null || points.isEmpty) {
      notifyListeners();
      return;
    }

    if (tip != null && !identical(tip, points.last)) points.add(tip);

    final stroke = Stroke(
      colorValue: _colorValue,
      width: _width,
      points: points.map((p) => p.rounded()).toList(),
      outline: buildOutline(points: points, width: _width, aspect: _drawAspect),
    );
    if (stroke.outline.isEmpty) {
      notifyListeners();
      return;
    }
    final pageStrokes = List.of(_pages[pageIndex] ?? const <Stroke>[]);
    pageStrokes.add(stroke);
    _pages[pageIndex] = pageStrokes;

    _undoStack.add(_AddOp(pageIndex: pageIndex, strokes: [stroke]));
    _redoStack.clear();
    _dirty = true;

    notifyListeners();
  }

  void _endLasso() {
    final pageIndex = _activePageIndex;
    final points = _lassoPoints;
    final dragging = _dragStartX != null;
    _activePageIndex = null;
    _activeIsTouch = false;
    _lassoPoints = null;
    _dragStartX = null;
    _dragStartY = null;

    if (dragging) {
      _commitDrag();
    } else if (pageIndex != null && points != null) {
      _closeLasso(pageIndex, points);
    }
    _pingLasso(pageIndex);
    notifyListeners();
  }

  void _closeLasso(int pageIndex, List<double> polygon) {
    _selection = null;
    final box = polygonBounds(polygon);
    if (polygon.length < 6 || box == null) return;
    if (box.maxX - box.minX < _lassoMinSpan &&
        box.maxY - box.minY < _lassoMinSpan) {
      return;
    }
    final strokes = _pages[pageIndex] ?? const <Stroke>[];
    final indices = selectStrokes(strokes, polygon);
    if (indices.isEmpty) return;
    _selection = _Selection(
      pageIndex: pageIndex,
      indices: indices,
      strokes: [for (final i in indices) strokes[i]],
      polygon: polygon,
    );
  }

  // Replaces the moved strokes in place rather than appending, so overlapping
  // strokes keep their z-order.
  void _commitDrag() {
    final selection = _selection;
    if (selection == null) return;
    final offset = _dragOffset.value;
    if (offset == Offset.zero) return;
    _dragOffset.value = Offset.zero;

    final pageStrokes = List.of(
      _pages[selection.pageIndex] ?? const <Stroke>[],
    );
    if (selection.indices.any((i) => i >= pageStrokes.length)) return;
    final moved = <(int, Stroke, Stroke)>[];
    final after = <Stroke>[];
    for (final i in selection.indices) {
      final before = pageStrokes[i];
      final shifted = translateStroke(before, offset.dx, offset.dy);
      pageStrokes[i] = shifted;
      moved.add((i, before, shifted));
      after.add(shifted);
    }
    _pages[selection.pageIndex] = pageStrokes;
    _undoStack.add(_MoveOp(pageIndex: selection.pageIndex, moved: moved));
    _redoStack.clear();
    _dirty = true;

    _selection = _Selection(
      pageIndex: selection.pageIndex,
      indices: selection.indices,
      strokes: after,
      polygon: translatePolygon(selection.polygon, offset.dx, offset.dy),
    );
  }

  void deleteSelection() {
    final selection = _selection;
    if (selection == null) return;
    final pageStrokes = List.of(
      _pages[selection.pageIndex] ?? const <Stroke>[],
    );
    final removed = <(int, Stroke)>[
      for (final i in selection.indices)
        if (i < pageStrokes.length) (i, pageStrokes[i]),
    ];
    for (var k = removed.length - 1; k >= 0; k--) {
      pageStrokes.removeAt(removed[k].$1);
    }
    if (removed.isNotEmpty) {
      _pages[selection.pageIndex] = pageStrokes;
      _undoStack.add(
        _EraseOp(pageIndex: selection.pageIndex, removed: removed),
      );
      _redoStack.clear();
      _dirty = true;
    }
    _resetLasso();
    notifyListeners();
  }

  void copySelection() {
    final selection = _selection;
    if (selection == null) return;
    _stash(selection, cut: false);
    notifyListeners();
  }

  void cutSelection() {
    final selection = _selection;
    if (selection == null) return;
    _stash(selection, cut: true);
    deleteSelection();
  }

  void _stash(_Selection selection, {required bool cut}) {
    _clipboard = _Clipboard(
      strokes: List.of(selection.strokes),
      aspect: pageAspect?.call(selection.pageIndex),
      // A copy leaves the originals in place, so a paste back onto that page
      // has to be nudged to read as a duplicate. A cut does not.
      copies: cut ? {} : {selection.pageIndex: 1},
    );
  }

  void pasteInto(int pageIndex) {
    final clipboard = _clipboard;
    if (clipboard == null || clipboard.strokes.isEmpty) return;

    final source = clipboard.aspect;
    final target = pageAspect?.call(pageIndex);
    var strokes = source == null || target == null
        ? clipboard.strokes
        : remapToAspect(clipboard.strokes, source, target);

    // Never hand the clipboard's own instances to a page: identity is what
    // erase, move and undo key on, so a second paste would alias the first.
    final nudge = _pasteNudge * (clipboard.copies[pageIndex] ?? 0);
    strokes = [for (final s in strokes) translateStroke(s, nudge, nudge)];
    clipboard.copies[pageIndex] = (clipboard.copies[pageIndex] ?? 0) + 1;

    final pageStrokes = List.of(_pages[pageIndex] ?? const <Stroke>[]);
    final start = pageStrokes.length;
    pageStrokes.addAll(strokes);
    _pages[pageIndex] = pageStrokes;

    _undoStack.add(_AddOp(pageIndex: pageIndex, strokes: strokes));
    _redoStack.clear();
    _dirty = true;

    _resetLasso();
    _selection = _Selection(
      pageIndex: pageIndex,
      indices: [for (var i = 0; i < strokes.length; i++) start + i],
      strokes: strokes,
      polygon: _boundsPolygon(strokes),
    );
    notifyListeners();
  }

  // A rectangle around the strokes, used as the drag hit region of a pasted
  // selection, which has no lasso of its own.
  static List<double> _boundsPolygon(List<Stroke> strokes) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var pad = 0.0;
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final b = stroke.bounds;
      minX = min(minX, b.minX);
      minY = min(minY, b.minY);
      maxX = max(maxX, b.maxX);
      maxY = max(maxY, b.maxY);
      pad = max(pad, stroke.width);
    }
    if (!minX.isFinite) return const [];
    return [
      minX - pad, minY - pad, //
      maxX + pad, minY - pad,
      maxX + pad, maxY + pad,
      minX - pad, maxY + pad,
    ];
  }

  // Drops an in-progress finger stroke without committing it, restoring
  // anything the eraser already removed. A stylus stroke keeps going.
  void cancelTouchStroke() {
    final pageIndex = _activePageIndex;
    if (pageIndex == null || !_activeIsTouch) return;
    final snapshot = _eraseSnapshot;
    if (snapshot != null) _pages[pageIndex] = snapshot;
    _lassoPoints = null;
    _dragStartX = null;
    _dragStartY = null;
    _dragOffset.value = Offset.zero;
    _activePageIndex = null;
    _activeIsTouch = false;
    _activePoints = null;
    _lastRawPoint = null;
    _livePath = null;
    _eraseSnapshot = null;
    _erasePending = null;
    _lastErasePoint = null;
    _pingLive(pageIndex);
    _pingLasso(pageIndex);
    notifyListeners();
  }

  // a/b are the eraser segment endpoints in raw normalized coords. Distances
  // are computed in page-width units (y scaled by aspect = height / width) so
  // the width threshold is isotropic.
  void _eraseSegment(StrokePoint a, StrokePoint b) {
    final pageIndex = _activePageIndex;
    final snapshot = _eraseSnapshot;
    final pending = _erasePending;
    if (pageIndex == null || snapshot == null || pending == null) return;

    final strokes = _pages[pageIndex];
    if (strokes == null || strokes.isEmpty) return;

    final aspect = _eraseAspect;
    final k = max(1.0, aspect);
    final ax = a.x, ay = a.y * aspect;
    final bx = b.x, by = b.y * aspect;
    final eraserHalf = _width / 2 * k;
    final segMinX = min(ax, bx) - eraserHalf;
    final segMinY = min(ay, by) - eraserHalf;
    final segMaxX = max(ax, bx) + eraserHalf;
    final segMaxY = max(ay, by) + eraserHalf;

    List<Stroke>? remaining;
    for (final stroke in strokes) {
      final half = stroke.width / 2 * k;
      final box = stroke.bounds;
      if (box.minX - half > segMaxX ||
          box.maxX + half < segMinX ||
          box.minY * aspect - half > segMaxY ||
          box.maxY * aspect + half < segMinY) {
        continue;
      }
      if (!_strokeHit(stroke, ax, ay, bx, by, aspect)) continue;
      final snapshotIndex = snapshot.indexOf(stroke);
      if (snapshotIndex < 0) continue;
      pending.add((snapshotIndex, stroke));
      remaining ??= List.of(strokes);
      remaining.removeWhere((s) => identical(s, stroke));
    }
    if (remaining != null) {
      _pages[pageIndex] = remaining;
      _dirty = true;
    }
  }

  bool _strokeHit(
    Stroke stroke,
    double ax,
    double ay,
    double bx,
    double by,
    double aspect,
  ) {
    final threshold = (stroke.width + _width) / 2 * max(1.0, aspect);
    final points = stroke.points;
    var px = points[0].x;
    var py = points[0].y * aspect;
    if (points.length == 1) {
      return _segSegDist(ax, ay, bx, by, px, py, px, py) < threshold;
    }
    for (var i = 1; i < points.length; i++) {
      final qx = points[i].x;
      final qy = points[i].y * aspect;
      if (_segSegDist(ax, ay, bx, by, px, py, qx, qy) < threshold) return true;
      px = qx;
      py = qy;
    }
    return false;
  }

  static double _segSegDist(
    double ax,
    double ay,
    double bx,
    double by,
    double px,
    double py,
    double qx,
    double qy,
  ) {
    final d1 = _cross(px, py, qx, qy, ax, ay);
    final d2 = _cross(px, py, qx, qy, bx, by);
    final d3 = _cross(ax, ay, bx, by, px, py);
    final d4 = _cross(ax, ay, bx, by, qx, qy);
    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return 0;
    }
    return min(
      min(
        _pointSegDist(ax, ay, px, py, qx, qy),
        _pointSegDist(bx, by, px, py, qx, qy),
      ),
      min(
        _pointSegDist(px, py, ax, ay, bx, by),
        _pointSegDist(qx, qy, ax, ay, bx, by),
      ),
    );
  }

  static double _cross(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) => (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);

  static double _pointSegDist(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0
        ? 0.0
        : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
    final cx = ax + t * dx - px;
    final cy = ay + t * dy - py;
    return sqrt(cx * cx + cy * cy);
  }

  bool get hasAnnotations => _pages.values.any((s) => s.isNotEmpty);

  // Leaves the clipboard alone: cutting strokes, wiping the page and pasting
  // them back is a legitimate move.
  void clearAll() {
    final active = _activePageIndex;
    _dirty = true;
    _pages.clear();
    _undoStack.clear();
    _redoStack.clear();
    _resetLasso();
    _pingLive(active);
    _activePageIndex = null;
    _activeIsTouch = false;
    _activePoints = null;
    _lastRawPoint = null;
    _livePath = null;
    _eraseSnapshot = null;
    _erasePending = null;
    _lastErasePoint = null;
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final op = _undoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    switch (op) {
      case _AddOp():
        for (final stroke in op.strokes) {
          pageStrokes.removeWhere((s) => identical(s, stroke));
        }
      case _EraseOp():
        for (final (index, stroke) in op.removed) {
          pageStrokes.insert(min(index, pageStrokes.length), stroke);
        }
      case _MoveOp():
        for (final (index, before, _) in op.moved) {
          if (index < pageStrokes.length) pageStrokes[index] = before;
        }
    }
    _pages[op.pageIndex] = pageStrokes;

    _redoStack.add(op);
    _dirty = true;

    // The selection holds instances that are no longer on the page.
    _resetLasso();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final op = _redoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    switch (op) {
      case _AddOp():
        pageStrokes.addAll(op.strokes);
      case _EraseOp():
        for (final (_, stroke) in op.removed) {
          pageStrokes.removeWhere((s) => identical(s, stroke));
        }
      case _MoveOp():
        for (final (index, _, after) in op.moved) {
          if (index < pageStrokes.length) pageStrokes[index] = after;
        }
    }
    _pages[op.pageIndex] = pageStrokes;

    _undoStack.add(op);
    _dirty = true;

    _resetLasso();
    notifyListeners();
  }

  Future<void> saveAll() async {
    if (!_dirty) return;
    await _repo.saveAnnotations(_scoreId, _pages);
    _dirty = false;
  }

  @override
  void dispose() {
    for (final n in _liveRepaints.values) {
      n.dispose();
    }
    for (final n in _lassoRepaints.values) {
      n.dispose();
    }
    _dragOffset.dispose();
    super.dispose();
  }
}
