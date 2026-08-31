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

class RoutineDetailViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  final String routineId;

  bool _loading = true;

  bool get loading => _loading;

  PracticeRoutine? _routine;

  PracticeRoutine? get routine => _routine;

  bool get missing => !_loading && _routine == null;

  /// True once the routine was loaded and has been deleted since.
  bool get deleted => _deleted;

  bool _deleted = false;

  StreamSubscription? _updatedRoutinesSub;

  StreamSubscription? _updatedExercisesSub;

  RoutineDetailViewModel({required this._repo, required this.routineId}) {
    _updatedRoutinesSub = _repo.updatedRoutineIds.listen((ids) {
      if (ids.contains(routineId)) load();
    });
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => load());
    load();
  }

  Future<void> load() async {
    final routine = await _repo.getRoutine(routineId);
    if (routine == null && _routine != null) _deleted = true;
    _routine = routine;
    _loading = false;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _updatedRoutinesSub?.cancel();
    _updatedExercisesSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
