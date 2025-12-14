import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewModel extends ChangeNotifier {
  File _file;

  PdfDocument? _document;
  PdfDocument? get document => _document;

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
    notifyListeners();
  }

  @override
  void dispose() {
    _document?.dispose();
    super.dispose();
  }
}
