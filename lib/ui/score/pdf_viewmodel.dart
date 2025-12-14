import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewModel extends ChangeNotifier {
  File _file;

  PdfDocument? _document;
  PdfDocument? get document => _document;

  int _currentPageIndex = 0;
  int get currentPageIndex => _currentPageIndex;

  PdfViewModel({required File file}) : _file = file {
    _loadDocument();
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
    _document?.dispose();
    super.dispose();
  }

  void nextPage(int pageCount) {
    final newIndex = _currentPageIndex + pageCount;
    if (newIndex >= (_document?.pages.length ?? 0)) {
      return;
    }
    _currentPageIndex = newIndex;
    notifyListeners();
  }

  void prevPage(int pageCount) {
    if (_currentPageIndex == 0) return;
    _currentPageIndex = max(_currentPageIndex - pageCount, 0);
    notifyListeners();
  }
}
