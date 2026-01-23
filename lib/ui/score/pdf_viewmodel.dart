import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';

class PdfViewModel extends ChangeNotifier {
  final MidiRepository _midiRepository;

  File _file;

  PdfDocument? _document;
  PdfDocument? get document => _document;

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  int _forwardPageCount = 1;
  int _backwardPageCount = 1;

  PdfViewModel({required File file, required MidiRepository midiRepository})
    : _file = file,
      _midiRepository = midiRepository {
    _midiRepository.addActionListener(_midiActionListener);
    _loadDocument();
  }

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
    _document?.dispose();
    super.dispose();
  }

  void nextPage() {
    final newIndex = _currentPageIndex + _forwardPageCount;
    if (newIndex >= (_document?.pages.length ?? 0)) {
      return;
    }
    _currentPageIndex = newIndex;
    notifyListeners();
  }

  void prevPage() {
    if (_currentPageIndex == 0) return;
    _currentPageIndex = max(_currentPageIndex - _backwardPageCount, 0);
    notifyListeners();
  }

  void updateForwardPageCount(int forwardPageCount) {
    _forwardPageCount = forwardPageCount;
  }

  void updateBackwardPageCount(int backwardPageCount) {
    _backwardPageCount = backwardPageCount;
  }
}
