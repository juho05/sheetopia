/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/utils/tag_sync.dart';

class PracticeRoutinesViewModel extends ChangeNotifier {
  static const int _pageSize = 100;

  final PracticeRepository _repo;

  List<PracticeRoutine> _routines = [];

  UnmodifiableListView<PracticeRoutine> get routines =>
      UnmodifiableListView(_routines);

  List<String> get loadedRoutineIds => [for (final r in _routines) r.id];

  Future<List<String>> getFilteredRoutineIds() async {
    return await _repo.getRoutineIds(
      filter: _filterSearch,
      instrument: _filterInstrument,
      source: _filterSource,
      tagIds: _filterTags.map((t) => t.id),
      tagMatch: _tagMatch,
    );
  }

  int _currentPage = -1;

  bool _hasNextPage = true;

  bool get hasNextPage => _hasNextPage;

  bool _loading = true;

  bool get loading => _loading;

  int? _resultCount;

  int? get resultCount => _resultCount;

  int? _totalCount;

  int? get totalCount => _totalCount;

  StreamSubscription? _updatedRoutinesSub;

  StreamSubscription? _updatedExercisesSub;

  late final TagSync _tagSync;

  PracticeRoutinesViewModel({
    required this._repo,
    required ScoresRepository scoresRepo,
  }) {
    _updatedRoutinesSub = _repo.updatedRoutineIds.listen((_) => _refresh());
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => _refresh());
    _tagSync = TagSync(
      repo: scoresRepo,
      currentTags: () => _filterTags,
      onChanged: setFilterTags,
    );
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final total = await _repo.countRoutines();
    final result = isFiltered
        ? await _repo.countRoutines(
            filter: _filterSearch,
            instrument: _filterInstrument,
            source: _filterSource,
            tagIds: _filterTags.map((t) => t.id),
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

  String _filterInstrument = "";

  String get filterInstrument => _filterInstrument;

  set filterInstrument(String instrument) {
    if (_filterInstrument == instrument) return;
    _filterInstrument = instrument;
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
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  Iterable<Tag> get filterTags => _filterTags;

  FilterMatchType _tagMatch = FilterMatchType.all;

  FilterMatchType get tagMatch => _tagMatch;

  set tagMatch(FilterMatchType value) {
    if (_tagMatch == value) return;
    _tagMatch = value;
    notifyListeners();
    _reset();
  }

  bool get hasFilters =>
      _filterInstrument.isNotEmpty ||
      _filterSource.isNotEmpty ||
      _filterTags.isNotEmpty;

  bool get isFiltered => _filterSearch.isNotEmpty || hasFilters;

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

  void setFilterTags(Iterable<Tag> tags) {
    _filterTags
      ..clear()
      ..addAll(tags);
    notifyListeners();
    _reset();
  }

  void clearFilters() {
    if (!hasFilters) return;
    _filterInstrument = "";
    _filterSource = "";
    _filterTags.clear();
    _tagMatch = FilterMatchType.all;
    notifyListeners();
    _reset();
  }

  Future<void> duplicate(String routineId) => _repo.duplicateRoutine(routineId);

  Future<void> delete(String routineId) => _repo.deleteRoutine(routineId);

  Future<Iterable<String>> getInstruments({String filter = ""}) async {
    return await _repo.getInstruments(filter: filter, size: 10);
  }

  Future<Iterable<String>> getSources({String filter = ""}) async {
    return await _repo.getSources(filter: filter, size: 10);
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
      final routines = await _loadRoutines(
        size: _pageSize,
        offset: page * _pageSize,
      );
      if (generation != _generation) return;
      _currentPage = page;
      _hasNextPage = routines.length == _pageSize;
      _routines.addAll(routines);
      _loading = false;
      notifyListeners();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<void> _refresh() {
    final loadedCount = (_currentPage + 1) * _pageSize;
    if (loadedCount == 0) return _refreshCounts();
    return _pendingLoad = _refreshPages(loadedCount, ++_generation);
  }

  Future<void> _refreshPages(int loadedCount, int generation) async {
    try {
      final routines = await _loadRoutines(size: loadedCount);
      if (generation != _generation) return;
      _routines = routines;
      _hasNextPage = routines.length == loadedCount;
      _loading = false;
      notifyListeners();
      _refreshCounts();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<List<PracticeRoutine>> _loadRoutines({
    required int size,
    int offset = 0,
  }) async {
    return await _repo.getRoutines(
      size: size,
      offset: offset,
      filter: _filterSearch,
      instrument: _filterInstrument,
      source: _filterSource,
      tagIds: _filterTags.map((t) => t.id),
      tagMatch: _tagMatch,
    );
  }

  Timer? _resetDebounce;

  void _reset() {
    if (_disposed) return;
    _resetDebounce?.cancel();
    _resetDebounce = Timer(const Duration(milliseconds: 50), () async {
      _generation++;
      _pendingLoad = null;
      _currentPage = -1;
      _routines = [];
      _hasNextPage = true;
      await loadNextPage();
      _refreshCounts();
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _resetDebounce?.cancel();
    _updatedRoutinesSub?.cancel();
    _updatedExercisesSub?.cancel();
    _tagSync.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
