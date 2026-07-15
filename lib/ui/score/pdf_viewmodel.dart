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
import 'package:sheetopia/data/repositories/annotations/annotations_repository.dart';
import 'package:sheetopia/data/repositories/annotations/stroke.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';

class PdfViewModel extends ChangeNotifier {
  final MidiRepository _midiRepository;
  final ScoreViewModel _scoreViewModel;
  final AnnotationsRepository _annotationsRepository;
  final String _scoreId;

  final Map<int, List<Stroke>> _annotations = {};

  StreamSubscription? _annotationsSub;

  File _file;

  PdfDocument? _document;

  PdfDocument? get document => _document;

  int _currentPageIndex = 0;

  int get currentPageIndex => _currentPageIndex;

  int _forwardPageCount = 1;
  int _backwardPageCount = 1;

  PdfViewModel({
    required File file,
    required MidiRepository midiRepository,
    required ScoreViewModel scoreViewModel,
    required AnnotationsRepository annotationsRepository,
    required String scoreId,
  }) : _file = file,
       _midiRepository = midiRepository,
       _scoreViewModel = scoreViewModel,
       _annotationsRepository = annotationsRepository,
       _scoreId = scoreId {
    _midiRepository.addActionListener(_midiActionListener);
    _loadDocument();
    _loadAnnotations();
    _annotationsSub = _annotationsRepository.updatedAnnotationScoreIds
        .where((id) => id == _scoreId)
        .listen((_) => _loadAnnotations());
  }

  Future<void> _loadAnnotations() async {
    final pages = await _annotationsRepository.getAnnotations(_scoreId);
    _annotations.clear();
    for (final page in pages) {
      _annotations[page.pageIndex] = page.strokes;
    }
    notifyListeners();
  }

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

  Future<void> _loadDocument() async {
    final document = await PdfDocument.openFile(_file.path);
    _document?.dispose();
    _document = document;
    _currentPageIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _midiRepository.removeActionListener(_midiActionListener);
    _annotationsSub?.cancel();
    _document?.dispose();
    super.dispose();
  }

  void nextPage() {
    final newIndex = _currentPageIndex + _forwardPageCount;
    if (newIndex >= (_document?.pages.length ?? 0)) {
      return;
    }
    _currentPageIndex = newIndex;
    _scoreViewModel.onNextPage();
    notifyListeners();
  }

  void prevPage() {
    if (_currentPageIndex == 0) return;
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
