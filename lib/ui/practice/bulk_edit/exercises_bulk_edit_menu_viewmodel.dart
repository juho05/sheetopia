/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/practice_repository.dart';

class ExercisesBulkEditMenuViewModel {
  final PracticeRepository _repo;

  List<String> _selectedExercises;

  ExercisesBulkEditMenuViewModel({
    required PracticeRepository repo,
    required Iterable<String> selectedExercises,
  }) : _repo = repo,
       _selectedExercises = selectedExercises.toList();

  void updateSelectedExercises(Iterable<String> selectedExercises) {
    _selectedExercises = selectedExercises.toList();
  }

  int get selectedCount => _selectedExercises.length;

  Future<void> editCategory(String? categoryId) async {
    await _repo.bulkUpdateExerciseCategory(_selectedExercises, categoryId);
  }

  Future<void> editInstrument(String instrument) async {
    await _repo.bulkUpdateExerciseInstrument(_selectedExercises, instrument);
  }

  Future<void> editSource(String source, String sourceLink) async {
    await _repo.bulkUpdateExerciseSource(
      _selectedExercises,
      source: source,
      sourceLink: sourceLink,
    );
  }

  Future<void> editTags(Set<String> addIds, Set<String> removeIds) async {
    await _repo.bulkEditExerciseTags(_selectedExercises, addIds, removeIds);
  }

  Future<int> addToRoutine(String routineId) async {
    final exerciseIds = List.of(_selectedExercises);
    await _repo.addRoutineEntries(routineId, exerciseIds);
    return exerciseIds.length;
  }

  Future<int> delete() async {
    final exerciseIds = _selectedExercises.toSet();
    await _repo.deleteExercises(exerciseIds);
    return exerciseIds.length;
  }

  Future<Iterable<String>> getInstruments({String filter = ""}) async {
    return await _repo.getInstruments(filter: filter, size: 10);
  }

  Future<Iterable<String>> getSources({String filter = ""}) async {
    return await _repo.getSources(filter: filter, size: 10);
  }
}
