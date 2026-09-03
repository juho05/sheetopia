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
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

typedef ExerciseGroup = ({ExerciseCategory? category, List<Exercise> exercise});

class ExercisesViewModel extends ChangeNotifier {
  static const int _pageSize = 100;

  final PracticeRepository _repo;

  List<Exercise> _exercises = [];

  List<ExerciseGroup> _groups = [];

  UnmodifiableListView<ExerciseGroup> get exercises =>
      UnmodifiableListView(_groups);

  List<String> get loadedExerciseIds => [for (final e in _exercises) e.id];

  int _currentPage = -1;

  bool _hasNextPage = true;

  bool get hasNextPage => _hasNextPage;

  bool _loading = true;

  bool get loading => _loading;

  int? _resultCount;

  int? get resultCount => _resultCount;

  int? _totalCount;

  int? get totalCount => _totalCount;

  StreamSubscription? _updatedExercisesSub;

  StreamSubscription? _updatedCategoriesSub;

  ExercisesViewModel({required this._repo}) {
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => _refresh());
    _updatedCategoriesSub = _repo.updatedCategoryIds.listen((_) => _refresh());
    _refreshCounts();
  }

  Future<void> _refreshCounts() async {
    final total = await _repo.countExercises();
    final result = isFiltered
        ? await _repo.countExercises(
            filter: _filterSearch,
            categoryId: _filterCategory?.id,
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

  ExerciseCategory? _filterCategory;

  ExerciseCategory? get filterCategory => _filterCategory;

  set filterCategory(ExerciseCategory? category) {
    if (_filterCategory?.id == category?.id) return;
    _filterCategory = category;
    notifyListeners();
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
    (a, b) => a.name.compareTo(b.name),
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
      _filterCategory != null ||
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

  void clearFilters() {
    if (!hasFilters) return;
    _filterCategory = null;
    _filterInstrument = "";
    _filterSource = "";
    _filterTags.clear();
    _tagMatch = FilterMatchType.all;
    notifyListeners();
    _reset();
  }

  Future<List<String>> getFilteredExerciseIds() async {
    return await _repo.getExerciseIds(
      filter: _filterSearch,
      categoryId: _filterCategory?.id,
      instrument: _filterInstrument,
      source: _filterSource,
      tagIds: _filterTags.map((t) => t.id),
      tagMatch: _tagMatch,
    );
  }

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
      final exercises = await _loadExercises(
        size: _pageSize,
        offset: page * _pageSize,
      );
      if (generation != _generation) return;
      _currentPage = page;
      _hasNextPage = exercises.length == _pageSize;
      _exercises.addAll(exercises);
      _groupExercises();
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
      final exercises = await _loadExercises(size: loadedCount);
      if (generation != _generation) return;
      _exercises = exercises;
      _hasNextPage = exercises.length == loadedCount;
      _groupExercises();
      _loading = false;
      notifyListeners();
      _refreshCounts();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<List<Exercise>> _loadExercises({
    required int size,
    int offset = 0,
  }) async {
    return await _repo.getExercises(
      size: size,
      offset: offset,
      filter: _filterSearch,
      categoryId: _filterCategory?.id,
      instrument: _filterInstrument,
      source: _filterSource,
      tagIds: _filterTags.map((t) => t.id),
      tagMatch: _tagMatch,
    );
  }

  void _groupExercises() {
    final groups = <ExerciseGroup>[];
    for (final exercise in _exercises) {
      final category = exercise.category;
      if (groups.isEmpty || groups.last.category?.id != category?.id) {
        groups.add((category: category, exercise: [exercise]));
      } else {
        groups.last.exercise.add(exercise);
      }
    }
    _groups = groups;
  }

  Timer? _resetDebounce;

  void _reset() {
    _resetDebounce?.cancel();
    _resetDebounce = Timer(const Duration(milliseconds: 50), () async {
      _generation++;
      _pendingLoad = null;
      _currentPage = -1;
      _exercises = [];
      _groups = [];
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
    _updatedExercisesSub?.cancel();
    _updatedCategoriesSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
