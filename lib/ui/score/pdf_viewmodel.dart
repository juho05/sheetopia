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
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';
import 'package:sheetopia/ui/setlists/setlist_navigation_viewmodel.dart';

class PdfViewModel extends ChangeNotifier {
  final MidiRepository _midiRepository;
  final ScoreViewModel _scoreViewModel;
  final ScoresRepository _scoresRepository;
  String _scoreId;

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

  PdfViewModel({
    required File file,
    required MidiRepository midiRepository,
    required ScoreViewModel scoreViewModel,
    required ScoresRepository scoresRepository,
    required String scoreId,
  }) : _file = file,
       _midiRepository = midiRepository,
       _scoreViewModel = scoreViewModel,
       _scoresRepository = scoresRepository,
       _scoreId = scoreId {
    _midiRepository.addActionListener(_midiActionListener);
    _loadDocument();
    _loadAnnotations();
    _annotationsSub = _scoresRepository.updatedScoreIds
        .where((s) => s.any((id) => id == _scoreId))
        .listen((_) => _loadAnnotations());
  }

  Future<void> _loadAnnotations() async {
    final pages = await _scoresRepository.getAnnotations(_scoreId);
    _annotations
      ..clear()
      ..addAll(pages);
    notifyListeners();
  }

  SetlistNavigationViewModel? get setlistNavigation =>
      _scoreViewModel.setlistNavigation;

  List<Stroke> strokesForPage(int pageNumber) =>
      _annotations[pageNumber - 1] ?? const [];

  void _midiActionListener(MidiAction action) {
    switch (action) {
      case MidiAction.nextPage:
        nextPage();
      case MidiAction.prevPage:
        prevPage();
    }
  }

  Future<void> updateFile(File file) async {
    _file = file;
    await _loadDocument();
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
    _loadInProgress = true;
    try {
      final document = await PdfDocument.openFile(_file.path);
      _document?.dispose();
      _document = document;
      _documentPath = _file.path;
      final landOnLastPage = _pendingLandOnLastPage;
      _pendingLandOnLastPage = false;
      _needsLastSpreadStart = landOnLastPage;
      _currentPageIndex = landOnLastPage ? document.pages.length - 1 : 0;
      _switchInFlight = false;
      _switching = false;
      notifyListeners();
    } finally {
      _loadInProgress = false;
    }
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
    _midiRepository.removeActionListener(_midiActionListener);
    _annotationsSub?.cancel();
    _document?.dispose();
    super.dispose();
  }

  void nextPage() {
    if (_document == null || _switchInFlight) return;
    final newIndex = _currentPageIndex + _forwardPageCount;
    if (newIndex >= _document!.pages.length) {
      if (_scoreViewModel.setlistNavigation?.advance() ?? false) {
        _pendingLandOnLastPage = false;
        _switchInFlight = true;
        _switching = true;
        _scoreViewModel.onNextPage();
        notifyListeners();
      }
      return;
    }
    _currentPageIndex = newIndex;
    _scoreViewModel.onNextPage();
    notifyListeners();
  }

  void prevPage() {
    if (_document == null || _switchInFlight) return;
    if (_currentPageIndex == 0) {
      if (_scoreViewModel.setlistNavigation?.goBack() ?? false) {
        _pendingLandOnLastPage = true;
        _switchInFlight = true;
        _switching = true;
        _scoreViewModel.onPrevPage();
        notifyListeners();
      }
      return;
    }
    _currentPageIndex = max(_currentPageIndex - _backwardPageCount, 0);
    _scoreViewModel.onPrevPage();
    notifyListeners();
  }

  void updateForwardPageCount(int forwardPageCount) {
    _forwardPageCount = forwardPageCount;
  }

  void updateBackwardPageCount(int backwardPageCount) {
    _backwardPageCount = backwardPageCount;
  }
}
