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
import 'package:sheetopia/data/repositories/practice/practice_record.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';

typedef PracticeRecordItem = ({
  PracticeRecord record,
  String? exerciseName,
  String? routineName,
});

class PracticeRecordsViewModel extends ChangeNotifier {
  static const int _pageSize = 100;

  final PracticeRepository _repo;

  List<PracticeRecordItem> _records = [];

  UnmodifiableListView<PracticeRecordItem> get records =>
      UnmodifiableListView(_records);

  int _currentPage = -1;

  bool _hasNextPage = true;

  bool get hasNextPage => _hasNextPage;

  bool _loading = true;

  bool get loading => _loading;

  final List<StreamSubscription> _subs = [];

  PracticeRecordsViewModel({required this._repo}) {
    _subs.addAll([
      _repo.updatedRecordIds.listen((_) => _refresh()),
      _repo.updatedExerciseIds.listen((_) => _refresh()),
      _repo.updatedRoutineIds.listen((_) => _refresh()),
    ]);
  }

  Future<String> create({
    required String exerciseId,
    required DateTime startedAt,
    required Duration duration,
  }) => _repo.createRecord(
    exerciseId: exerciseId,
    startedAt: startedAt,
    duration: duration,
  );

  Future<void> update(
    String recordId, {
    required DateTime startedAt,
    required Duration duration,
  }) => _repo.updateRecord(recordId, startedAt: startedAt, duration: duration);

  Future<void> delete(String recordId) => _repo.deleteRecord(recordId);

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
      final records = await _loadRecords(
        size: _pageSize,
        offset: page * _pageSize,
      );
      if (generation != _generation) return;
      _currentPage = page;
      _hasNextPage = records.length == _pageSize;
      _records.addAll(records);
      _loading = false;
      notifyListeners();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<void> _refresh() {
    final loadedCount = (_currentPage + 1) * _pageSize;
    if (loadedCount == 0) return Future.value();
    return _pendingLoad = _refreshPages(loadedCount, ++_generation);
  }

  Future<void> _refreshPages(int loadedCount, int generation) async {
    try {
      final records = await _loadRecords(size: loadedCount);
      if (generation != _generation) return;
      _records = records;
      _hasNextPage = records.length == loadedCount;
      _loading = false;
      notifyListeners();
    } finally {
      if (generation == _generation) _pendingLoad = null;
    }
  }

  Future<List<PracticeRecordItem>> _loadRecords({
    required int size,
    int offset = 0,
  }) async {
    final records = await _repo.getRecords(size: size, offset: offset);
    final exercises = await _repo.getExercisesById({
      for (final r in records) r.exerciseId,
    });
    final routines = await _repo.getRoutineNames({
      for (final r in records) ?r.routineId,
    });
    return [
      for (final record in records)
        (
          record: record,
          exerciseName: exercises[record.exerciseId]?.name,
          routineName: routines[record.routineId],
        ),
    ];
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
