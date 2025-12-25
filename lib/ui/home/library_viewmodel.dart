import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  static const int _pageSize = 100;

  final ScoresRepository _repo;

  List<Score> _scores = [];
  UnmodifiableListView<Score> get scores => UnmodifiableListView(_scores);

  int _currentPage = -1;

  bool _hasNextPage = true;
  bool get hasNextPage => _hasNextPage;

  String _filter = "";
  set filter(String filter) {
    if (_filter == filter) return;
    _filter = filter;
    _reset();
  }

  StreamSubscription? _updatedScoresSub;
  LibraryViewModel({required ScoresRepository repo}) : _repo = repo {
    _updatedScoresSub = _repo.updatedScoreIds.listen((_) => _refresh());
  }

  Future<void> loadNextPage() async {
    if (!_hasNextPage) return;
    _currentPage++;
    final scores = await _repo.getScores(
      size: _pageSize,
      offset: _currentPage * _pageSize,
      filter: _filter,
    );
    _hasNextPage = scores.length == _pageSize;
    _scores.addAll(scores);
    notifyListeners();
  }

  Future<void> _refresh() async {
    final totalCount = (_currentPage + 1) * _pageSize;
    if (totalCount == 0) return;
    final scores = await _repo.getScores(size: totalCount, filter: _filter);
    _scores = scores.toList();
    _hasNextPage = scores.length == totalCount;
    notifyListeners();
  }

  Future<void> _reset() async {
    _currentPage = -1;
    _scores = [];
    _hasNextPage = true;
    await loadNextPage();
  }

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    super.dispose();
  }
}
