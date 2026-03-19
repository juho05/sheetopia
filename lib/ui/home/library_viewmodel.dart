import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

class LibraryViewModel extends ChangeNotifier {
  static const int _pageSize = 100;

  final ScoresRepository _repo;

  List<Score> _scores = [];
  UnmodifiableListView<Score> get scores => UnmodifiableListView(_scores);

  int _currentPage = -1;

  bool _hasNextPage = true;
  bool get hasNextPage => _hasNextPage;

  String _filterSearch = "";
  set filterSearch(String filter) {
    if (_filterSearch == filter) return;
    _filterSearch = filter;
    _reset();
  }

  String _filterComposer = "";
  String get filterComposer => _filterComposer;
  set filterComposer(String composer) {
    if (_filterComposer == composer) return;
    _filterComposer = composer;
    notifyListeners();
    _reset();
  }

  final SplayTreeSet<Tag> _filterTags = SplayTreeSet(
    (a, b) => a.name.compareTo(b.name),
  );
  Iterable<Tag> get filterTags => _filterTags;

  final SplayTreeSet<String> _filterInstruments = SplayTreeSet();
  Iterable<String> get filterInstruments => _filterInstruments;

  final SplayTreeSet<String> _filterGenres = SplayTreeSet();
  Iterable<String> get filterGenres => _filterGenres;

  StreamSubscription? _updatedScoresSub;
  StreamSubscription? _updatedTagsSub;
  StreamSubscription? _lastOpenedSub;
  LibraryViewModel({required ScoresRepository repo}) : _repo = repo {
    _updatedScoresSub = _repo.updatedScoreIds.listen((_) => _refresh());
    _lastOpenedSub = _repo.lastOpenedChanged.listen((_) => _refresh());
    _updatedTagsSub = _repo.updatedTagIds
        .where((ids) => ids.intersection(_filterTags).isNotEmpty)
        .listen((_) => _refreshFilterTags());
  }

  Future<void> loadNextPage() async {
    if (!_hasNextPage) return;
    _currentPage++;
    final scores = await _loadScores(
      size: _pageSize,
      offset: _currentPage * _pageSize,
    );
    _hasNextPage = scores.length == _pageSize;
    _scores.addAll(scores);
    notifyListeners();
  }

  Future<void> _refresh() async {
    final totalCount = (_currentPage + 1) * _pageSize;
    if (totalCount == 0) return;
    final scores = await _loadScores(size: totalCount);
    _scores = scores.toList();
    _hasNextPage = scores.length == totalCount;
    notifyListeners();
  }

  Future<Iterable<Score>> _loadScores({
    required int size,
    int offset = 0,
  }) async {
    return await _repo.getScores(
      size: size,
      offset: offset,
      filter: _filterSearch,
      instruments: _filterInstruments,
      genres: _filterGenres,
      composer: _filterComposer,
      tagIds: _filterTags.map((t) => t.id),
    );
  }

  Future<void> _refreshFilterTags() async {
    final newTags = await _repo.getTagsById(_filterTags.map((t) => t.id));
    _filterTags.clear();
    _filterTags.addAll(newTags);
    notifyListeners();
  }

  Timer? _resetDebounce;
  Future<void> _reset() async {
    _resetDebounce = Timer(const Duration(milliseconds: 250), () async {
      _currentPage = -1;
      _scores = [];
      _hasNextPage = true;
      _resetDebounce?.cancel();
      await loadNextPage();
    });
  }

  void addFilterTags(Iterable<Tag> tags) {
    _filterTags.addAll(tags);
    notifyListeners();
    _reset();
  }

  void removeFilterTag(Tag tag) {
    _filterTags.remove(tag);
    notifyListeners();
    _reset();
  }

  void addFilterInstrument(String instrument) {
    _filterInstruments.add(instrument);
    notifyListeners();
    _reset();
  }

  void removeFilterInstrument(String instrument) {
    _filterInstruments.remove(instrument);
    notifyListeners();
    _reset();
  }

  void addFilterGenre(String genre) {
    _filterGenres.add(genre);
    notifyListeners();
    _reset();
  }

  void removeFilterGenre(String genre) {
    _filterGenres.remove(genre);
    notifyListeners();
    _reset();
  }

  Future<Iterable<String>> getInstruments({String filter = ""}) async {
    return await _repo.getInstruments(
      filter: filter,
      size: 10,
      exclude: filterInstruments,
    );
  }

  Future<Iterable<String>> getGenres({String filter = ""}) async {
    return await _repo.getGenres(
      filter: filter,
      size: 10,
      exclude: filterGenres,
    );
  }

  Future<Iterable<String>> getComposers({String filter = ""}) async {
    return await _repo.getComposers(filter: filter, size: 10);
  }

  void clearFilters() {
    _filterTags.clear();
    _filterComposer = "";
    _filterGenres.clear();
    _filterInstruments.clear();
    notifyListeners();
    _reset();
  }

  @override
  void dispose() {
    _resetDebounce?.cancel();
    _updatedTagsSub?.cancel();
    _updatedScoresSub?.cancel();
    _lastOpenedSub?.cancel();
    super.dispose();
  }
}
