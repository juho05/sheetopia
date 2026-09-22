/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';

class RoutineDetailViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  final String routineId;

  bool _loading = true;

  bool get loading => _loading;

  PracticeRoutine? _routine;

  PracticeRoutine? get routine => _routine;

  bool get missing => !_loading && _routine == null;

  final Map<String, List<Score>> _scoresByExercise = {};

  List<Score> scoresFor(String exerciseId) =>
      _scoresByExercise[exerciseId] ?? const [];

  Map<String, Duration> _practiced = const {};

  Duration practicedFor(String routineEntryId) =>
      _practiced[routineEntryId] ?? Duration.zero;

  bool get hasProgress => _practiced.isNotEmpty;

  Duration _practicedTotal = Duration.zero;

  Duration get practicedTotal => _practicedTotal;

  /// True once the routine was loaded and has been deleted since.
  bool get deleted => _deleted;

  bool _deleted = false;

  StreamSubscription? _updatedRoutinesSub;

  StreamSubscription? _updatedExercisesSub;

  StreamSubscription? _updatedRecordsSub;

  RoutineDetailViewModel({required this._repo, required this.routineId}) {
    _updatedRoutinesSub = _repo.updatedRoutineIds.listen((ids) {
      if (ids.contains(routineId)) load();
    });
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => load());
    _updatedRecordsSub = _repo.updatedRecordIds.listen((_) => load());
    load();
  }

  Future<void> resetProgress() async {
    final progress = await _repo.getRoutineProgress(
      routineId,
      target: _routine?.targetDuration,
    );
    if (progress.running != null) return;
    await _repo.resetRoutineProgress(routineId);
    await load();
  }

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    final routine = await _repo.getRoutine(routineId);
    if (generation != _loadGeneration) return;
    if (routine == null && _routine != null) _deleted = true;

    final scores = <String, List<Score>>{};
    for (final exerciseId
        in routine?.entries.map((e) => e.exercise.id).toSet() ??
            const <String>{}) {
      scores[exerciseId] = await _repo.getExerciseScores(exerciseId);
      if (generation != _loadGeneration) return;
    }

    final progress = routine == null
        ? PracticeProgress.empty
        : await _repo.getRoutineProgress(
            routineId,
            target: routine.targetDuration,
          );
    if (generation != _loadGeneration) return;

    final now = DateTime.now();
    _routine = routine;
    _scoresByExercise
      ..clear()
      ..addAll(scores);
    _practiced = progress.byRoutineEntry(now: now);
    _practicedTotal = progress.total(now: now);
    _loading = false;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _updatedRoutinesSub?.cancel();
    _updatedExercisesSub?.cancel();
    _updatedRecordsSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
