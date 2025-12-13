import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class HomeViewModel extends ChangeNotifier {
  PdfDocument? _document;
  PdfDocument? get pdf => _document;

  int _currentPage = 0;
  int get currentPageIndex => _currentPage;

  PdfPage get currentPage => _document!.pages[_currentPage];
  int get currentPageNumber => currentPage.pageNumber;

  HomeViewModel() {
    _load();
  }

  Future<void> _load() async {
    final document = await PdfDocument.openAsset("assets/test.pdf");
    _document = document;
    _currentPage = 0;
    notifyListeners();
  }

  void nextPage() {
    if (_document == null) return;
    if (_currentPage >= _document!.pages.length - 1) return;
    _currentPage++;
    notifyListeners();
  }

  void prevPage() {
    if (_document == null) return;
    if (_currentPage <= 0) return;
    _currentPage--;
    notifyListeners();
  }
}
