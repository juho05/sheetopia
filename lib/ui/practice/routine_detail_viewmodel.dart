/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/practice/practice_session.dart';
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

  bool get hasSessionTimes => _practiced.isNotEmpty;

  Duration get practicedThisSession =>
      _practiced.values.fold(Duration.zero, (total, d) => total + d);

  /// True once the routine was loaded and has been deleted since.
  bool get deleted => _deleted;

  bool _deleted = false;

  StreamSubscription? _updatedRoutinesSub;

  StreamSubscription? _updatedExercisesSub;

  StreamSubscription? _updatedSessionsSub;

  RoutineDetailViewModel({required this._repo, required this.routineId}) {
    _updatedRoutinesSub = _repo.updatedRoutineIds.listen((ids) {
      if (ids.contains(routineId)) load();
    });
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => load());
    _updatedSessionsSub = _repo.updatedSessionIds.listen((_) => load());
    load();
  }

  Future<void> startNewSession() async {
    await _repo.startNewSession(
      routineId: routineId,
      routineTarget: _routine?.targetDuration ?? Duration.zero,
    );
    await load();
  }

  Future<PracticeSession?> _currentSession(PracticeRoutine? routine) async {
    if (routine == null) return null;
    return _repo.getCurrentSession(
      routineId: routineId,
      routineTarget: routine.targetDuration,
    );
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

    final session = await _currentSession(routine);
    if (generation != _loadGeneration) return;

    _routine = routine;
    _scoresByExercise
      ..clear()
      ..addAll(scores);
    _practiced =
        session?.durationsByRoutineEntry(now: DateTime.now()) ?? const {};
    _loading = false;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _updatedRoutinesSub?.cancel();
    _updatedExercisesSub?.cancel();
    _updatedSessionsSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
