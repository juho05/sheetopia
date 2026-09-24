/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/score/score_file_view.dart';

class PdfViewModel extends ChangeNotifier implements ScoreFileView {
  final ScoresRepository _scoresRepository;
  String _scoreId;

  final bool Function()? _onOverflowForward;
  final bool Function()? _onOverflowBackward;
  final void Function(bool forward)? _onPageTurned;

  String? _nextPath;
  String? _previousPath;

  final Map<int, List<Stroke>> _annotations = {};

  StreamSubscription? _annotationsSub;

  File _file;

  PdfDocument? _document;

  PdfDocument? get document => _document;

  String? _documentPath;

  String? get documentPath => _documentPath;

  int _currentPageIndex = 0;

  int get currentPageIndex => _currentPageIndex;

  int _forwardPageCount = 1;
  int _backwardPageCount = 1;

  bool _pendingLandOnLastPage = false;

  bool _needsLastSpreadStart = false;

  bool get needsLastSpreadStart => _needsLastSpreadStart;

  bool _switchInFlight = false;

  bool _switching = false;

  bool get switching => _switching;

  bool _loadInProgress = false;

  int _loadGeneration = 0;

  bool _loadFailed = false;

  bool get loadFailed => _loadFailed;

  bool _disposed = false;

  final Map<String, Future<PdfDocument>> _preloadedDocuments = {};

  bool _isPreloaded(String? path) =>
      path != null && _preloadedDocuments.containsKey(path);

  PdfViewModel({
    required this._file,
    required this._scoresRepository,
    required this._scoreId,
    this._nextPath,
    this._previousPath,
    this._onOverflowForward,
    this._onOverflowBackward,
    this._onPageTurned,
  }) {
    _loadDocument();
    _loadAnnotations();
    _annotationsSub = _scoresRepository.updatedScoreIds
        .where((s) => s.any((id) => id == _scoreId))
        .listen((_) => _loadAnnotations());
  }

  Future<void> _loadAnnotations() async {
    final pages = await _scoresRepository.getAnnotations(_scoreId);
    if (_disposed) return;
    _annotations
      ..clear()
      ..addAll(pages);
    notifyListeners();
  }

  List<Stroke> strokesForPage(int pageNumber) =>
      _annotations[pageNumber - 1] ?? const [];

  Future<void> updateFile(File file) async {
    _file = file;
    await _loadDocument();
  }

  void updateNeighborPaths({String? next, String? previous}) {
    if (next == _nextPath && previous == _previousPath) return;
    _nextPath = next;
    _previousPath = previous;
    _syncPreloadedDocuments();
  }

  Future<void> updateScoreId(String scoreId) async {
    if (_scoreId == scoreId) return;
    _scoreId = scoreId;
    _annotations.clear();
    await _loadAnnotations();
  }

  void clearSwitchInFlight() {
    _switchInFlight = false;
    if (!_loadInProgress) {
      _switching = false;
      _pendingLandOnLastPage = false;
    }
  }

  Future<void> _loadDocument() async {
    final generation = ++_loadGeneration;
    final path = _file.path;
    _loadInProgress = true;
    PdfDocument? document;
    try {
      final preloaded = _preloadedDocuments.remove(path);
      document = await (preloaded ?? PdfDocument.openFile(path));
    } catch (e, st) {
      if (_disposed || generation != _loadGeneration) return;
      Log.error("Failed to open PDF $path", e: e, st: st);
    } finally {
      if (generation == _loadGeneration) _loadInProgress = false;
    }
    if (_disposed || generation != _loadGeneration) {
      document?.dispose();
      return;
    }
    _document?.dispose();
    _document = document;
    _documentPath = path;
    _loadFailed = document == null;
    final landOnLastPage = _pendingLandOnLastPage && document != null;
    _pendingLandOnLastPage = false;
    _needsLastSpreadStart = landOnLastPage;
    _currentPageIndex = landOnLastPage ? document.pages.length - 1 : 0;
    _switchInFlight = false;
    _switching = false;
    notifyListeners();
  }

  void updateLastSpreadStart(int start) {
    if (!_needsLastSpreadStart) return;
    _needsLastSpreadStart = false;
    if (start == _currentPageIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentPageIndex = start;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _annotationsSub?.cancel();
    _document?.dispose();
    for (final document in _preloadedDocuments.values) {
      _disposeWhenReady(document);
    }
    _preloadedDocuments.clear();
    super.dispose();
  }

  @override
  void nextPage() {
    if ((_document == null && !_loadFailed) || _switchInFlight) return;
    final newIndex = _currentPageIndex + _forwardPageCount;
    if (newIndex >= (_document?.pages.length ?? 0)) {
      final preloaded = _isPreloaded(_nextPath);
      if (_onOverflowForward?.call() ?? false) {
        _pendingLandOnLastPage = false;
        _switchInFlight = true;
        _switching = !preloaded;
        _onPageTurned?.call(true);
        notifyListeners();
      }
      return;
    }
    _currentPageIndex = newIndex;
    _onPageTurned?.call(true);
    notifyListeners();
  }

  @override
  void prevPage() {
    if ((_document == null && !_loadFailed) || _switchInFlight) return;
    if (_currentPageIndex == 0) {
      final preloaded = _isPreloaded(_previousPath);
      if (_onOverflowBackward?.call() ?? false) {
        _pendingLandOnLastPage = true;
        _switchInFlight = true;
        _switching = !preloaded;
        _onPageTurned?.call(false);
        notifyListeners();
      }
      return;
    }
    _currentPageIndex = max(_currentPageIndex - _backwardPageCount, 0);
    _onPageTurned?.call(false);
    notifyListeners();
  }

  void updateForwardPageCount(int forwardPageCount) {
    _forwardPageCount = forwardPageCount;
    _syncPreloadedDocuments();
  }

  void updateBackwardPageCount(int backwardPageCount) {
    _backwardPageCount = backwardPageCount;
  }

  void _syncPreloadedDocuments() {
    final document = _document;
    if (document == null || _switchInFlight || _switching || _loadInProgress) {
      return;
    }

    final wanted = <String>{};
    if (_currentPageIndex + _forwardPageCount >= document.pages.length) {
      if (_nextPath != null) wanted.add(_nextPath!);
    }
    if (_currentPageIndex == 0) {
      if (_previousPath != null) wanted.add(_previousPath!);
    }
    wanted.remove(_documentPath);

    for (final path in _preloadedDocuments.keys.toList()) {
      if (wanted.contains(path)) continue;
      _disposeWhenReady(_preloadedDocuments.remove(path)!);
    }
    for (final path in wanted) {
      _preloadedDocuments.putIfAbsent(path, () {
        final document = PdfDocument.openFile(path);
        document.then((_) {}, onError: (_) {});
        return document;
      });
    }
  }

  void _disposeWhenReady(Future<PdfDocument> document) {
    document.then((d) => d.dispose()).ignore();
  }
}
