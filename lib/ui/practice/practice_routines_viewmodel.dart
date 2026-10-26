/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/common/filter_viewmodel.dart';
import 'package:sheetopia/utils/tag_sync.dart';

class PracticeRoutinesViewModel extends ChangeNotifier with FilterViewModel {
  static const int _pageSize = 100;

  final PracticeRepository _repo;

  List<PracticeRoutine> _routines = [];

  UnmodifiableListView<PracticeRoutine> get routines =>
      UnmodifiableListView(_routines);

  List<String> get loadedRoutineIds => [for (final r in _routines) r.id];

  Future<List<String>> getFilteredRoutineIds() async {
    return await _repo.getRoutineIds(
      filter: filterSearch,
      instrument: _filterInstrument,
      source: filterSource,
      tagIds: filterTags.map((t) => t.id),
      tagMatch: tagMatch,
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

  StreamSubscription? _updatedRecordsSub;

  late final TagSync _tagSync;

  Duration _practicedToday = Duration.zero;

  Duration get practicedToday => _practicedToday;

  DateTime _practicedDay = DateTime.now();

  Timer? _dayCheck;

  late final AppLifecycleListener _lifecycle;

  PracticeRoutinesViewModel({
    required this._repo,
    required ScoresRepository scoresRepo,
  }) {
    _updatedRoutinesSub = _repo.updatedRoutineIds.listen((_) => _refresh());
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => _refresh());
    _updatedRecordsSub = _repo.updatedRecordIds.listen(
      (_) => refreshPracticedToday(),
    );
    _tagSync = TagSync(
      repo: scoresRepo,
      currentTags: () => filterTags,
      onChanged: setFilterTags,
    );
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    _startDayCheck();
    _refreshCounts();
    refreshPracticedToday();
  }

  Future<void> refreshPracticedToday() async {
    _practicedDay = DateTime.now();
    final practiced = await _repo.getPracticedOn(_practicedDay);
    if (practiced == _practicedToday) return;
    _practicedToday = practiced;
    notifyListeners();
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        refreshPracticedToday();
        _startDayCheck();
      case AppLifecycleState.paused || AppLifecycleState.detached:
        _dayCheck?.cancel();
        _dayCheck = null;
      case AppLifecycleState.inactive || AppLifecycleState.hidden:
        break;
    }
  }

  void _startDayCheck() {
    _dayCheck ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (PracticeProgress.sameDay(DateTime.now(), _practicedDay)) return;
      refreshPracticedToday();
    });
  }

  Future<void> _refreshCounts() async {
    final total = await _repo.countRoutines();
    final result = isFiltered
        ? await _repo.countRoutines(
            filter: filterSearch,
            instrument: _filterInstrument,
            source: filterSource,
            tagIds: filterTags.map((t) => t.id),
            tagMatch: tagMatch,
          )
        : total;
    _totalCount = total;
    _resultCount = result;
    notifyListeners();
  }

  String _filterInstrument = "";

  String get filterInstrument => _filterInstrument;

  set filterInstrument(String instrument) {
    if (_filterInstrument == instrument) return;
    _filterInstrument = instrument;
    notifyListeners();
    _reset();
  }

  @override
  void refilter() => _reset();

  @override
  bool get hasOwnFilters => _filterInstrument.isNotEmpty;

  @override
  void clearOwnFilters() => _filterInstrument = "";

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
      filter: filterSearch,
      instrument: _filterInstrument,
      source: filterSource,
      tagIds: filterTags.map((t) => t.id),
      tagMatch: tagMatch,
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
    _dayCheck?.cancel();
    _lifecycle.dispose();
    _updatedRoutinesSub?.cancel();
    _updatedExercisesSub?.cancel();
    _updatedRecordsSub?.cancel();
    _tagSync.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
