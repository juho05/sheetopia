/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';

class _UndoOp {
  final int pageIndex;
  final Stroke stroke;

  const _UndoOp({required this.pageIndex, required this.stroke});
}

class AnnotateViewModel extends ChangeNotifier {
  static const int black = 0xFF000000;
  static const int red = 0xFFFF0000;
  static const int blue = 0xFF2196F3;
  static const int green = 0xFF4CAF50;
  static const int highlighterYellow = 0x88FFEB3B;

  static const List<int> palette = [black, red, blue, green, highlighterYellow];

  static const double minWidth = 0.0015;
  static const double maxWidth = 0.02;

  final ScoresRepository _repo;
  final String _scoreId;

  final Map<int, List<Stroke>> _pages = {};
  bool _dirty = false;

  final List<_UndoOp> _undoStack = [];
  final List<_UndoOp> _redoStack = [];

  int _colorValue = black;

  int get colorValue => _colorValue;

  double _width = 0.004;

  double get width => _width;

  bool _drawMode =
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  bool get drawMode => _drawMode;

  int? _activePageIndex;
  List<StrokePoint>? _activePoints;

  AnnotateViewModel({
    required ScoresRepository repo,
    required String scoreId,
  }) : _repo = repo,
       _scoreId = scoreId {
    _load();
  }

  Future<void> _load() async {
    _pages.addAll(await _repo.getAnnotations(_scoreId));
    notifyListeners();
  }

  void setColor(int color) {
    _colorValue = color;
    notifyListeners();
  }

  void setWidth(double width) {
    _width = width;
    notifyListeners();
  }

  void toggleDrawMode() {
    _drawMode = !_drawMode;
    notifyListeners();
  }

  List<Stroke> strokesFor(int pageIndex) => _pages[pageIndex] ?? const [];

  Stroke? liveStrokeFor(int pageIndex) {
    if (_activePageIndex != pageIndex || _activePoints == null) return null;
    return Stroke(
      colorValue: _colorValue,
      width: _width,
      points: _activePoints!,
    );
  }

  void startStroke(int pageIndex, StrokePoint p) {
    _activePageIndex = pageIndex;
    _activePoints = [p];
    notifyListeners();
  }

  void appendPoint(StrokePoint p) {
    if (_activePoints == null) return;
    _activePoints!.add(p);
    notifyListeners();
  }

  void endStroke() {
    final pageIndex = _activePageIndex;
    final points = _activePoints;
    _activePageIndex = null;
    _activePoints = null;

    if (pageIndex == null || points == null || points.isEmpty) {
      notifyListeners();
      return;
    }

    final stroke = Stroke(
      colorValue: _colorValue,
      width: _width,
      points: points,
    );
    final pageStrokes = List.of(_pages[pageIndex] ?? const <Stroke>[]);
    pageStrokes.add(stroke);
    _pages[pageIndex] = pageStrokes;

    _undoStack.add(_UndoOp(pageIndex: pageIndex, stroke: stroke));
    _redoStack.clear();
    _dirty = true;

    notifyListeners();
  }

  bool get hasAnnotations => _pages.values.any((s) => s.isNotEmpty);

  void clearAll() {
    _dirty = true;
    _pages.clear();
    _undoStack.clear();
    _redoStack.clear();
    _activePageIndex = null;
    _activePoints = null;
    notifyListeners();
  }

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final op = _undoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    pageStrokes.removeWhere((s) => identical(s, op.stroke));
    _pages[op.pageIndex] = pageStrokes;

    _redoStack.add(op);
    _dirty = true;

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final op = _redoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    pageStrokes.add(op.stroke);
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
}
