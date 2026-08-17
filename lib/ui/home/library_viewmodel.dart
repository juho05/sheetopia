/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
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

  int? _resultCount;
  int? get resultCount => _resultCount;

  int? _totalCount;
  int? get totalCount => _totalCount;

  bool get isFiltered =>
      _filterSearch.isNotEmpty ||
      _filterComposer.isNotEmpty ||
      _filterSource.isNotEmpty ||
      _filterInstruments.isNotEmpty ||
      _filterGenres.isNotEmpty ||
      _filterTags.isNotEmpty;

  Future<void> _refreshCounts() async {
    final total = await _repo.countScores();
    final result = isFiltered
        ? await _repo.countScores(
            filter: _filterSearch,
            instruments: _filterInstruments,
            genres: _filterGenres,
            composer: _filterComposer,
            source: _filterSource,
            tagIds: _filterTags.map((t) => t.id),
            genreMatch: _genreMatch,
            instrumentMatch: _instrumentMatch,
            tagMatch: _tagMatch,
          )
        : total;
    _totalCount = total;
    _resultCount = result;
    notifyListeners();
  }

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

  String _filterSource = "";
  String get filterSource => _filterSource;
  set filterSource(String source) {
    if (_filterSource == source) return;
    _filterSource = source;
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

  FilterMatchType _genreMatch = FilterMatchType.any;
  FilterMatchType get genreMatch => _genreMatch;
  set genreMatch(FilterMatchType value) {
    if (_genreMatch == value) return;
    _genreMatch = value;
    notifyListeners();
    _reset();
  }

  FilterMatchType _instrumentMatch = FilterMatchType.exact;
  FilterMatchType get instrumentMatch => _instrumentMatch;
  set instrumentMatch(FilterMatchType value) {
    if (_instrumentMatch == value) return;
    _instrumentMatch = value;
    notifyListeners();
    _reset();
  }

  FilterMatchType _tagMatch = FilterMatchType.all;
  FilterMatchType get tagMatch => _tagMatch;
  set tagMatch(FilterMatchType value) {
    if (_tagMatch == value) return;
    _tagMatch = value;
    notifyListeners();
    _reset();
  }

  StreamSubscription? _updatedScoresSub;
  StreamSubscription? _updatedTagsSub;
  StreamSubscription? _lastOpenedSub;
  LibraryViewModel({required ScoresRepository repo}) : _repo = repo {
    _updatedScoresSub = _repo.updatedScoreIds.listen((_) => _refresh());
    _lastOpenedSub = _repo.lastOpenedChanged.listen((_) => _refresh());
    _updatedTagsSub = _repo.updatedTagIds
        .where((ids) => ids.intersection(_filterTags).isNotEmpty)
        .listen((_) => _refreshFilterTags());
    _refreshCounts();
  }

  int _generation = 0;
  Future<void>? _pendingLoad;

  Future<void> loadNextPage() {
    final pending = _pendingLoad;
    if (pending != null) return pending;
    if (!_hasNextPage) return Future.value();
    return _pendingLoad = _loadPage(_currentPage + 1, _generation);
  }

  Future<void> _loadPage(int page, int generation) async {
    try {
      final scores = await _loadScores(
        size: _pageSize,
        offset: page * _pageSize,
      );
      if (generation != _generation) return;
      _currentPage = page;
      _hasNextPage = scores.length == _pageSize;
      _scores.addAll(scores);
      notifyListeners();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<void> _refresh() {
    final totalCount = (_currentPage + 1) * _pageSize;
    if (totalCount == 0) return Future.value();
    return _pendingLoad = _refreshPages(totalCount, ++_generation);
  }

  Future<void> _refreshPages(int totalCount, int generation) async {
    try {
      final scores = await _loadScores(size: totalCount);
      if (generation != _generation) return;
      _scores = scores.toList();
      _hasNextPage = scores.length == totalCount;
      notifyListeners();
      _refreshCounts();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
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
      source: _filterSource,
      tagIds: _filterTags.map((t) => t.id),
      genreMatch: _genreMatch,
      instrumentMatch: _instrumentMatch,
      tagMatch: _tagMatch,
    );
  }

  Future<void> _refreshFilterTags() async {
    final newTags = await _repo.getTagsById(_filterTags.map((t) => t.id));
    _filterTags.clear();
    _filterTags.addAll(newTags);
    notifyListeners();
  }

  Timer? _resetDebounce;
  void _reset() {
    _resetDebounce?.cancel();
    _resetDebounce = Timer(const Duration(milliseconds: 250), () async {
      _generation++;
      _pendingLoad = null;
      _currentPage = -1;
      _scores = [];
      _hasNextPage = true;
      await loadNextPage();
      _refreshCounts();
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

  Future<Iterable<String>> getSources({String filter = ""}) async {
    return await _repo.getSources(filter: filter, size: 10);
  }

  void clearFilters() {
    _filterTags.clear();
    _filterComposer = "";
    _filterSource = "";
    _filterGenres.clear();
    _filterInstruments.clear();
    _genreMatch = FilterMatchType.any;
    _instrumentMatch = FilterMatchType.exact;
    _tagMatch = FilterMatchType.all;
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
