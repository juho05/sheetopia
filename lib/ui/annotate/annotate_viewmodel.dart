/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/annotations/annotations_repository.dart';
import 'package:sheetopia/data/repositories/annotations/stroke.dart';

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

  final AnnotationsRepository _repo;
  final String _scoreId;

  final Map<int, List<Stroke>> _pages = {};
  final Set<int> _dirtyPages = {};

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
    required AnnotationsRepository repo,
    required String scoreId,
  }) : _repo = repo,
       _scoreId = scoreId {
    _load();
  }

  Future<void> _load() async {
    final pages = await _repo.getAnnotations(_scoreId);
    for (final page in pages) {
      _pages[page.pageIndex] = List.of(page.strokes);
    }
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
    _dirtyPages.add(pageIndex);

    notifyListeners();
  }

  bool get hasAnnotations => _pages.values.any((s) => s.isNotEmpty);

  void clearAll() {
    _dirtyPages.addAll(_pages.keys);
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
    _dirtyPages.add(op.pageIndex);

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final op = _redoStack.removeLast();

    final pageStrokes = List.of(_pages[op.pageIndex] ?? const <Stroke>[]);
    pageStrokes.add(op.stroke);
    _pages[op.pageIndex] = pageStrokes;

    _undoStack.add(op);
    _dirtyPages.add(op.pageIndex);

    notifyListeners();
  }

  Future<void> saveAll() async {
    final pageIndices = List.of(_dirtyPages);
    for (final pageIndex in pageIndices) {
      await _repo.savePage(
        _scoreId,
        PageAnnotations(pageIndex: pageIndex, strokes: strokesFor(pageIndex)),
      );
    }
    _dirtyPages.clear();
  }
}
