/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class BulkEditMenuViewModel {
  Set<String> _selectedScores;

  final ScoresRepository _repo;

  BulkEditMenuViewModel({
    required ScoresRepository repo,
    required Iterable<String> selectedScores,
  }) : _repo = repo,
       _selectedScores = selectedScores.toSet();

  void updateSelectedScores(Iterable<String> selectedScores) {
    _selectedScores = selectedScores.toSet();
  }

  Future<void> editTags(Set<String> addIds, Set<String> removeIds) async {
    await _repo.bulkEditScoreTags(_selectedScores, addIds, removeIds);
  }
}
