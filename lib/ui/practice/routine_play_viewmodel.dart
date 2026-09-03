/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';

class RoutinePlayEntry {
  final PracticeRoutineEntry entry;
  final List<Score> scores;

  int selected;

  RoutinePlayEntry({
    required this.entry,
    required this.scores,
    required this.selected,
  });

  String get id => entry.id;

  Exercise get exercise => entry.exercise;

  Score? get score =>
      selected < 0 || selected >= scores.length ? null : scores[selected];

  bool get scoresUnavailable => score == null && scores.isNotEmpty;
}

class RoutinePlayViewModel extends ChangeNotifier implements ScoreSequence {
  final PracticeRepository _repo;
  final ScoresRepository _scoresRepo;

  final String routineId;

  final int? startIndex;

  PracticeRoutine? _routine;

  List<RoutinePlayEntry> _entries = [];

  int _index = -1;

  bool _loading = true;

  bool _deleted = false;

  int _loadGeneration = 0;

  StreamSubscription? _routineSub;
  StreamSubscription? _exerciseSub;
  StreamSubscription? _scoresSub;

  RoutinePlayViewModel({
    required this._repo,
    required this._scoresRepo,
    required this.routineId,
    this.startIndex,
  }) {
    _routineSub = _repo.updatedRoutineIds
        .where((ids) => ids.contains(routineId))
        .listen((_) => _load());
    _exerciseSub = _repo.updatedExerciseIds
        .where((ids) => ids.any(_exerciseIds.contains))
        .listen((_) => _load());
    _scoresSub = _scoresRepo.updatedScoreIds
        .where((ids) => ids.any(_scoreIds.contains))
        .listen((_) => _load());
    _load();
  }

  PracticeRoutine? get routine => _routine;

  String get name => _routine?.name ?? "";

  bool get loading => _loading;

  @override
  bool get deleted => _deleted;

  UnmodifiableListView<RoutinePlayEntry> get entries =>
      UnmodifiableListView(_entries);

  int get length => _entries.length;

  @override
  int get position => _index;

  RoutinePlayEntry? get currentEntry =>
      _index < 0 || _index >= _entries.length ? null : _entries[_index];

  Exercise? get currentExercise => currentEntry?.exercise;

  String get exerciseName => currentExercise?.name ?? "";

  UnmodifiableListView<Score> get scores =>
      UnmodifiableListView(currentEntry?.scores ?? const []);

  int get scoreIndex => currentEntry?.selected ?? -1;

  @override
  String? get currentScoreId => currentEntry?.score?.id;

  bool get hasNext => _index >= 0 && _index < _entries.length - 1;

  bool get hasPrevious => _index > 0;

  @override
  File? get nextFile => hasNext ? _entries[_index + 1].score?.file : null;

  @override
  File? get previousFile =>
      hasPrevious ? _entries[_index - 1].score?.file : null;

  Set<String> get _exerciseIds => _entries.map((e) => e.exercise.id).toSet();

  Set<String> get _scoreIds =>
      _entries.expand((e) => e.scores).map((s) => s.id).toSet();

  @override
  bool next() {
    if (!hasNext) return false;
    _index++;
    notifyListeners();
    return true;
  }

  @override
  bool previous() {
    if (!hasPrevious) return false;
    _index--;
    notifyListeners();
    return true;
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _entries.length || index == _index) return;
    _index = index;
    notifyListeners();
  }

  void selectScore(int index) {
    final entry = currentEntry;
    if (entry == null) return;
    if (index < 0 || index >= entry.scores.length) return;
    if (index == entry.selected || !_playable(entry.scores[index])) return;
    entry.selected = index;
    notifyListeners();
  }

  bool _playable(Score score) => score.file != null;

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final first = _loading;
    final routine = await _repo.getRoutine(routineId);
    if (generation != _loadGeneration) return;
    if (routine == null) {
      _deleted = true;
      _loading = false;
      notifyListeners();
      return;
    }

    final scores = <String, List<Score>>{};
    for (final exerciseId
        in routine.entries.map((e) => e.exercise.id).toSet()) {
      scores[exerciseId] = await _repo.getExerciseScores(exerciseId);
      if (generation != _loadGeneration) return;
    }

    final selections = {
      for (final entry in _entries) entry.id: (entry.score?.id, entry.selected),
    };
    final previousEntryId = currentEntry?.id;
    final previousIndex = _index;

    _routine = routine;
    _entries = [
      for (final entry in routine.entries)
        _buildEntry(entry, scores[entry.exercise.id] ?? const [], selections),
    ];
    _index = _resolveIndex(first, previousEntryId, previousIndex);
    _loading = false;
    notifyListeners();
  }

  RoutinePlayEntry _buildEntry(
    PracticeRoutineEntry entry,
    List<Score> scores,
    Map<String, (String?, int)> selections,
  ) {
    final (scoreId, index) = selections[entry.id] ?? (null, -1);
    return RoutinePlayEntry(
      entry: entry,
      scores: scores,
      selected: _resolveSelection(scores, scoreId, index, entry.defaultScoreId),
    );
  }

  int _resolveSelection(
    List<Score> scores,
    String? previousScoreId,
    int previousIndex,
    String? defaultScoreId,
  ) {
    if (previousScoreId != null) {
      if (previousIndex >= 0 &&
          previousIndex < scores.length &&
          scores[previousIndex].id == previousScoreId &&
          _playable(scores[previousIndex])) {
        return previousIndex;
      }
      final index = scores.indexWhere(
        (s) => s.id == previousScoreId && _playable(s),
      );
      if (index >= 0) return index;
    }
    if (defaultScoreId != null) {
      final index = scores.indexWhere(
        (s) => s.id == defaultScoreId && _playable(s),
      );
      if (index >= 0) return index;
    }
    return scores.indexWhere(_playable);
  }

  int _resolveIndex(bool first, String? previousEntryId, int previousIndex) {
    if (_entries.isEmpty) return -1;
    if (first) {
      final start = startIndex ?? 0;
      return start.clamp(0, _entries.length - 1);
    }
    if (previousEntryId != null) {
      final index = _entries.indexWhere((e) => e.id == previousEntryId);
      if (index >= 0) return index;
    }
    return previousIndex.clamp(0, _entries.length - 1);
  }

  @override
  void dispose() {
    _routineSub?.cancel();
    _exerciseSub?.cancel();
    _scoresSub?.cancel();
    super.dispose();
  }
}
