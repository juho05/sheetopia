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
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';

class ExercisePlayViewModel extends ChangeNotifier implements ScoreSequence {
  final PracticeRepository _repo;
  final ScoresRepository _scoresRepo;

  String _exerciseId;

  Exercise? _exercise;

  List<Score> _scores = [];

  int _index = -1;

  bool _loading = true;

  bool _deleted = false;

  int _loadGeneration = 0;

  StreamSubscription? _exerciseSub;
  StreamSubscription? _scoresSub;

  ExercisePlayViewModel({
    required this._repo,
    required this._scoresRepo,
    required this._exerciseId,
  }) {
    _exerciseSub = _repo.updatedExerciseIds
        .where((ids) => ids.contains(_exerciseId))
        .listen((_) => _load());
    _scoresSub = _scoresRepo.updatedScoreIds
        .where((ids) => ids.any(_scoreIds.contains))
        .listen((_) => _load());
    _load();
  }

  String get exerciseId => _exerciseId;

  Exercise? get exercise => _exercise;

  String get exerciseName => _exercise?.name ?? "";

  UnmodifiableListView<Score> get scores => UnmodifiableListView(_scores);

  bool get loading => _loading;

  @override
  int get position => _index;

  @override
  bool get deleted => _deleted;

  Score? get currentScore =>
      _index < 0 || _index >= _scores.length ? null : _scores[_index];

  @override
  String? get currentScoreId => currentScore?.id;

  bool get hasScores => _scores.isNotEmpty;

  Set<String> get _scoreIds => _scores.map((s) => s.id).toSet();

  @override
  File? get nextFile => null;

  @override
  File? get previousFile => null;

  @override
  bool next() => false;

  @override
  bool previous() => false;

  Future<void> showExercise(String exerciseId) async {
    if (exerciseId == _exerciseId) return;
    _exerciseId = exerciseId;
    await _load(keepSelection: false);
  }

  void selectScore(int index) {
    if (index < 0 || index >= _scores.length) return;
    if (index == _index || !_playable(_scores[index])) return;
    _index = index;
    notifyListeners();
  }

  bool _playable(Score score) => score.file != null;

  Future<void> _load({bool keepSelection = true}) async {
    final generation = ++_loadGeneration;
    final exerciseId = _exerciseId;
    final exercise = await _repo.getExercise(exerciseId);
    if (generation != _loadGeneration) return;
    if (exercise == null) {
      _deleted = true;
      _loading = false;
      notifyListeners();
      return;
    }
    final scores = await _repo.getExerciseScores(exerciseId);
    if (generation != _loadGeneration) return;

    final previousScoreId = keepSelection ? currentScoreId : null;
    _exercise = exercise;
    _scores = scores;
    _index = _resolveIndex(previousScoreId);
    _loading = false;
    notifyListeners();
  }

  int _resolveIndex(String? previousScoreId) {
    if (previousScoreId != null) {
      if (_index >= 0 &&
          _index < _scores.length &&
          _scores[_index].id == previousScoreId &&
          _playable(_scores[_index])) {
        return _index;
      }
      final index = _scores.indexWhere(
        (s) => s.id == previousScoreId && _playable(s),
      );
      if (index >= 0) return index;
    }
    return _scores.indexWhere(_playable);
  }

  @override
  void dispose() {
    _exerciseSub?.cancel();
    _scoresSub?.cancel();
    super.dispose();
  }
}
