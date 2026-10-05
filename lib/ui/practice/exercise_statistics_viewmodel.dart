/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/ui/practice/exercise_duration_bar.dart';

/// Reaches back from today, which counts as the first day.
enum ExerciseStatisticsRange {
  week(7),
  month(30),
  threeMonths(90),
  year(365),
  all(null);

  final int? days;

  const ExerciseStatisticsRange(this.days);
}

class ExerciseStatisticsViewModel extends ChangeNotifier {
  static const int _pageSize = 50;
  static const String deletedExerciseName = ExerciseDurationBar.deletedName;

  final PracticeRepository _repo;
  final DateTime Function() _clock;

  List<ExercisePracticeTotal> _exercises = [];

  UnmodifiableListView<ExercisePracticeTotal> get exercises =>
      UnmodifiableListView(_exercises);

  Duration _longest = Duration.zero;

  Duration get longest => _longest;

  int _loadedCount = 0;

  bool _hasNextPage = true;

  bool get hasNextPage => _hasNextPage;

  bool _loading = true;

  bool get loading => _loading;

  final List<StreamSubscription> _subs = [];

  ExerciseStatisticsViewModel({required this._repo, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _subs.addAll([
      _repo.updatedRecordIds.listen((_) => _reload(_loadedCount)),
      _repo.updatedExerciseIds.listen((_) => _reload(_loadedCount)),
    ]);
  }

  ExerciseStatisticsRange _range = ExerciseStatisticsRange.month;

  ExerciseStatisticsRange get range => _range;

  set range(ExerciseStatisticsRange value) {
    if (value == _range) return;
    _range = value;
    notifyListeners();
    _reload(_pageSize);
  }

  String _filterSearch = "";

  bool get isFiltered => _filterSearch.isNotEmpty;

  set filterSearch(String filter) {
    if (_filterSearch == filter) return;
    _filterSearch = filter;
    _reload(_pageSize);
  }

  DateTime? get _from {
    final days = _range.days;
    if (days == null) return null;
    final now = _clock();
    return DateTime(now.year, now.month, now.day - days + 1);
  }

  int _generation = 0;
  Future<void>? _pendingLoad;

  Future<void> loadNextPage() {
    final pending = _pendingLoad;
    if (pending != null) return pending;
    if (!_hasNextPage) return Future.value();
    return _pendingLoad = _load(
      size: _pageSize,
      offset: _loadedCount,
      generation: _generation,
    );
  }

  /// Replaces the list with its first [size] entries.
  Future<void> _reload(int size) => _pendingLoad = _load(
    size: math.max(size, _pageSize),
    offset: 0,
    generation: ++_generation,
  );

  Future<void> _load({
    required int size,
    required int offset,
    required int generation,
  }) async {
    try {
      final exercises = await _repo.getExercisePracticeTotals(
        size: size,
        offset: offset,
        filter: _filterSearch,
        from: _from,
        deletedName: deletedExerciseName,
      );
      final top = offset != 0
          ? null
          : _filterSearch.isEmpty
          ? exercises
          : await _repo.getExercisePracticeTotals(
              size: 1,
              from: _from,
              deletedName: deletedExerciseName,
            );
      if (generation != _generation) return;
      if (top != null) {
        _longest = top.firstOrNull?.duration ?? Duration.zero;
        _exercises = exercises;
      } else {
        _exercises.addAll(exercises);
      }
      _loadedCount = offset + size;
      _hasNextPage = exercises.length == size;
      _loading = false;
      notifyListeners();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
