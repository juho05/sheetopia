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

import 'package:material_ui/material_ui.dart';
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
  String? _nextScoreId;
  bool _neighborsSettled;

  bool _gradual;

  bool get gradual => _gradual;

  // the following score as seen from the shown document, its pages continue
  // the shown ones in gradual mode
  String? _spillPath;
  String? _spillScoreId;

  bool _half = false;

  // upper half of the following page is requested on top of the current page
  bool get half => _half;

  double _split = 0.5;

  double get split => _split;

  String _documentScoreId;

  final Map<String, Map<int, List<Stroke>>> _annotations = {};

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
  final Map<String, PdfDocument> _readyDocuments = {};

  bool _isPreloaded(String? path) =>
      path != null &&
      (_preloadedDocuments.containsKey(path) ||
          (_gradual && path == _documentPath));

  PdfDocument? get spillDocument {
    final path = _spillPath;
    if (!_gradual || _document == null || path == null) return null;
    return path == _documentPath ? _document : _readyDocuments[path];
  }

  String? get spillPath => _spillPath;

  PdfViewModel({
    required this._file,
    required this._scoresRepository,
    required this._scoreId,
    this._gradual = false,
    this._nextPath,
    this._previousPath,
    this._nextScoreId,
    this._neighborsSettled = true,
    this._onOverflowForward,
    this._onOverflowBackward,
    this._onPageTurned,
  }) : _documentScoreId = _scoreId {
    _loadDocument();
    _syncAnnotations();
    _annotationsSub = _scoresRepository.updatedScoreIds.listen((ids) {
      for (final id in _annotatedScoreIds) {
        if (ids.contains(id)) _loadAnnotations(id);
      }
    });
  }

  Set<String> get _annotatedScoreIds => {
    _scoreId,
    _documentScoreId,
    if (_gradual) ?_spillScoreId,
  };

  Future<void> _loadAnnotations(String scoreId) async {
    final pages = await _scoresRepository.getAnnotations(scoreId);
    if (_disposed || !_annotatedScoreIds.contains(scoreId)) return;
    _annotations[scoreId] = pages;
    notifyListeners();
  }

  void _syncAnnotations() {
    final wanted = _annotatedScoreIds;
    _annotations.removeWhere((id, _) => !wanted.contains(id));
    for (final id in wanted) {
      if (!_annotations.containsKey(id)) _loadAnnotations(id);
    }
  }

  List<Stroke> strokesForPage(int pageNumber, {bool spill = false}) =>
      _annotations[spill ? _spillScoreId : _documentScoreId]?[pageNumber - 1] ??
      const [];

  Future<void> updateFile(File file) async {
    _file = file;
    await _loadDocument();
  }

  void updateNeighbors({
    String? next,
    String? previous,
    String? nextScoreId,
    required bool settled,
  }) {
    if (next == _nextPath &&
        previous == _previousPath &&
        nextScoreId == _nextScoreId &&
        settled == _neighborsSettled) {
      return;
    }
    _nextPath = next;
    _previousPath = previous;
    _nextScoreId = nextScoreId;
    _neighborsSettled = settled;
    // while a switch is pending the neighbors already belong to the new score
    if (settled && !_loadInProgress) _applySpill();
    _syncPreloadedDocuments();
  }

  void _applySpill() {
    final path = _nextScoreId == null ? null : _nextPath;
    _spillPath = path;
    _spillScoreId = path == null ? null : _nextScoreId;
    _syncAnnotations();
  }

  void updateGradual(bool gradual) {
    if (gradual == _gradual) return;
    _gradual = gradual;
    _half = false;
    _syncAnnotations();
  }

  void moveSplit(double delta) {
    _split = (_split + delta).clamp(0.1, 0.9);
    notifyListeners();
  }

  void updateScoreId(String scoreId) {
    if (_scoreId == scoreId) return;
    _scoreId = scoreId;
    if (!_loadInProgress) _documentScoreId = scoreId;
    _syncAnnotations();
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
      final shown = _gradual && path == _documentPath ? _document : null;
      document = await (shown != null
          ? Future.value(shown)
          : preloaded ?? PdfDocument.openFile(path));
    } catch (e, st) {
      if (_disposed || generation != _loadGeneration) return;
      Log.error("Failed to open PDF $path", e: e, st: st);
    } finally {
      if (generation == _loadGeneration) _loadInProgress = false;
    }
    // kept until here so the spill pages stay on screen during the switch
    if (identical(_readyDocuments[path], document)) {
      _readyDocuments.remove(path);
    }
    if (_disposed || generation != _loadGeneration) {
      if (!identical(document, _document)) document?.dispose();
      return;
    }
    final old = _document;
    final oldPath = _documentPath;
    _document = document;
    _documentPath = path;
    _documentScoreId = _scoreId;
    if (old != null && !identical(old, document)) {
      // the old document may be shown again as neighbor right away
      if (_gradual &&
          document != null &&
          oldPath != null &&
          oldPath != path &&
          !_preloadedDocuments.containsKey(oldPath)) {
        _preloadedDocuments[oldPath] = Future.value(old);
        _readyDocuments[oldPath] = old;
      } else {
        old.dispose();
      }
    }
    _spillPath = null;
    _spillScoreId = null;
    if (_neighborsSettled) {
      _applySpill();
    } else {
      _syncAnnotations();
    }
    _loadFailed = document == null;
    final landOnLastPage = _pendingLandOnLastPage && document != null;
    _pendingLandOnLastPage = false;
    _needsLastSpreadStart = landOnLastPage && !_gradual;
    _currentPageIndex = landOnLastPage ? document.pages.length - 1 : 0;
    _half = landOnLastPage && spillDocument != null;
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
    _readyDocuments.clear();
    super.dispose();
  }

  void _overflowForward() {
    final preloaded = _isPreloaded(_nextPath);
    if (_onOverflowForward?.call() ?? false) {
      _pendingLandOnLastPage = false;
      _switchInFlight = true;
      _switching = !preloaded;
      _onPageTurned?.call(true);
      notifyListeners();
    }
  }

  void _overflowBackward() {
    final preloaded = _isPreloaded(_previousPath);
    if (_onOverflowBackward?.call() ?? false) {
      _pendingLandOnLastPage = true;
      _switchInFlight = true;
      _switching = !preloaded;
      _onPageTurned?.call(false);
      notifyListeners();
    }
  }

  @override
  void nextPage() {
    if ((_document == null && !_loadFailed) || _switchInFlight) return;
    if (_gradual) return _nextPageGradual();
    final newIndex = _currentPageIndex + _forwardPageCount;
    if (newIndex >= (_document?.pages.length ?? 0)) {
      _overflowForward();
      return;
    }
    _currentPageIndex = newIndex;
    _onPageTurned?.call(true);
    notifyListeners();
  }

  @override
  void prevPage() {
    if ((_document == null && !_loadFailed) || _switchInFlight) return;
    if (_gradual) return _prevPageGradual();
    if (_currentPageIndex == 0) {
      _overflowBackward();
      return;
    }
    _currentPageIndex = max(_currentPageIndex - _backwardPageCount, 0);
    _onPageTurned?.call(false);
    notifyListeners();
  }

  void _nextPageGradual() {
    final length = _document?.pages.length ?? 0;
    final total = length + (spillDocument?.pages.length ?? 0);
    final halfShown =
        _half && _forwardPageCount == 1 && _currentPageIndex + 1 < total;
    if (!halfShown) _half = false;
    if (halfShown) {
      if (_currentPageIndex + 1 >= length) return _overflowForward();
      _half = false;
      _currentPageIndex++;
    } else if (_forwardPageCount == 1 && _currentPageIndex + 1 < total) {
      _half = true;
    } else if (_forwardPageCount > 1 &&
        _currentPageIndex + _forwardPageCount < total &&
        _currentPageIndex + 1 < length) {
      _currentPageIndex++;
    } else {
      return _overflowForward();
    }
    _onPageTurned?.call(true);
    notifyListeners();
  }

  void _prevPageGradual() {
    final length = _document?.pages.length ?? 0;
    final total = length + (spillDocument?.pages.length ?? 0);
    final halfShown =
        _half && _forwardPageCount == 1 && _currentPageIndex + 1 < total;
    if (halfShown) {
      _half = false;
    } else if (_currentPageIndex > 0) {
      _currentPageIndex--;
      _half = _backwardPageCount == 1;
    } else {
      _half = false;
      return _overflowBackward();
    }
    _onPageTurned?.call(false);
    notifyListeners();
  }

  // in gradual mode this is the number of pages shown from the current page
  void updateForwardPageCount(int forwardPageCount) {
    _forwardPageCount = forwardPageCount;
    _syncPreloadedDocuments();
  }

  // in gradual mode this is the number of pages shown from the previous page
  void updateBackwardPageCount(int backwardPageCount) {
    _backwardPageCount = backwardPageCount;
  }

  void _syncPreloadedDocuments() {
    final document = _document;
    if (document == null || _switchInFlight || _switching || _loadInProgress) {
      return;
    }

    final wanted = <String>{};
    // gradual turns show the neighbor one step before leaving the document
    final lookahead = _gradual ? 1 : 0;
    if (_currentPageIndex + _forwardPageCount + lookahead >=
        document.pages.length) {
      if (_nextPath != null) wanted.add(_nextPath!);
      if (_gradual && _spillPath != null) wanted.add(_spillPath!);
    }
    if (_currentPageIndex == 0) {
      if (_previousPath != null) wanted.add(_previousPath!);
    }
    wanted.remove(_documentPath);

    for (final path in _preloadedDocuments.keys.toList()) {
      if (wanted.contains(path)) continue;
      _readyDocuments.remove(path);
      _disposeWhenReady(_preloadedDocuments.remove(path)!);
    }
    for (final path in wanted) {
      _preloadedDocuments.putIfAbsent(path, () {
        final document = PdfDocument.openFile(path);
        document.then((loaded) {
          if (_disposed || _preloadedDocuments[path] != document) return;
          _readyDocuments[path] = loaded;
          if (_gradual) notifyListeners();
        }, onError: (_) {});
        return document;
      });
    }
  }

  void _disposeWhenReady(Future<PdfDocument> document) {
    document.then((d) => d.dispose()).ignore();
  }
}
