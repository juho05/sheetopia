/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/stroke_outline.dart';

sealed class _UndoOp {
  final int pageIndex;

  const _UndoOp({required this.pageIndex});
}

class _AddOp extends _UndoOp {
  final Stroke stroke;

  const _AddOp({required super.pageIndex, required this.stroke});
}

class _EraseOp extends _UndoOp {
  // (index in the pre-erase snapshot, stroke), ascending by index.
  final List<(int, Stroke)> removed;

  const _EraseOp({required super.pageIndex, required this.removed});
}

// Fires on every live-stroke sample so only the live layer repaints, without
// rebuilding the widget tree or the static (committed) strokes layer.
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

  final ScoresRepository _repo;
  final String _scoreId;

  final Map<int, List<Stroke>> _pages = {};
  bool _dirty = false;

  final _liveRepaint = _Notifier();

  Listenable get liveRepaint => _liveRepaint;

  final List<_UndoOp> _undoStack = [];
  final List<_UndoOp> _redoStack = [];

  int _colorValue = red;

  int get colorValue => _colorValue;

  bool _eraser = false;

  bool get eraser => _eraser;

  double _width = 0.004;

  double get width => _width;

  bool _drawMode =
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool get drawMode => _drawMode;

  int? _activePageIndex;
  List<StrokePoint>? _activePoints;

  List<Stroke>? _eraseSnapshot;
  List<(int, Stroke)>? _erasePending;
  StrokePoint? _lastErasePoint;
  double _eraseAspect = 1.0;
  double _drawAspect = 1.0;

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
    _eraser = false;
    notifyListeners();
  }

  void setEraser() {
    _eraser = true;
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

  StrokePoint? eraserCursorFor(int pageIndex) {
    if (_activePageIndex != pageIndex || _eraseSnapshot == null) return null;
    return _lastErasePoint;
  }

  ({int colorValue, double width, List<StrokePoint> points})? liveStrokeFor(
    int pageIndex,
  ) {
    if (_activePageIndex != pageIndex || _activePoints == null) return null;
    return (colorValue: _colorValue, width: _width, points: _activePoints!);
  }

  void startStroke(int pageIndex, StrokePoint p, double aspect) {
    _activePageIndex = pageIndex;
    if (_eraser) {
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
    _liveRepaint.ping();
  }

  void appendPoint(StrokePoint p, double aspect) {
    if (_eraseSnapshot != null) {
      final last = _lastErasePoint ?? p;
      _lastErasePoint = p;
      _eraseAspect = aspect;
      _eraseSegment(last, p);
      notifyListeners();
      return;
    }
    if (_activePoints == null) return;
    _drawAspect = aspect;
    _activePoints!.add(p);
    _liveRepaint.ping();
  }

  void endStroke() {
    final pageIndex = _activePageIndex;
    final points = _activePoints;
    final erased = _erasePending;
    _activePageIndex = null;
    _activePoints = null;
    _eraseSnapshot = null;
    _erasePending = null;
    _lastErasePoint = null;
    _liveRepaint.ping();

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

    final stroke = Stroke(
      colorValue: _colorValue,
      width: _width,
      points: points.map((p) => p.rounded()).toList(),
      outline: buildOutline(
        points: points,
        width: _width,
        aspect: _drawAspect,
      ),
    );
    if (stroke.outline.isEmpty) {
      notifyListeners();
      return;
    }
    final pageStrokes = List.of(_pages[pageIndex] ?? const <Stroke>[]);
    pageStrokes.add(stroke);
    _pages[pageIndex] = pageStrokes;

    _undoStack.add(_AddOp(pageIndex: pageIndex, stroke: stroke));
    _redoStack.clear();
    _dirty = true;

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

  void clearAll() {
    _dirty = true;
    _pages.clear();
    _undoStack.clear();
    _redoStack.clear();
    _activePageIndex = null;
    _activePoints = null;
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
        pageStrokes.removeWhere((s) => identical(s, op.stroke));
      case _EraseOp():
        for (final (index, stroke) in op.removed) {
          pageStrokes.insert(min(index, pageStrokes.length), stroke);
        }
    }
    _pages[op.pageIndex] = pageStrokes;

    _redoStack.add(op);
    _dirty = true;

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final op = _redoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    switch (op) {
      case _AddOp():
        pageStrokes.add(op.stroke);
      case _EraseOp():
        for (final (_, stroke) in op.removed) {
          pageStrokes.removeWhere((s) => identical(s, stroke));
        }
    }
    _pages[op.pageIndex] = pageStrokes;

    _undoStack.add(op);
    _dirty = true;

    notifyListeners();
  }

  Future<void> saveAll() async {
    if (!_dirty) return;
    await _repo.saveAnnotations(_scoreId, _pages);
    _dirty = false;
  }

  @override
  void dispose() {
    _liveRepaint.dispose();
    super.dispose();
  }
}
