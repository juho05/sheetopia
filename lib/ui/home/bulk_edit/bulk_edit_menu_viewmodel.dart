/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';

class BulkEditMenuViewModel {
  List<String> _selectedScores;

  final ScoresRepository _repo;
  final SetlistsRepository _setlistsRepo;

  BulkEditMenuViewModel({
    required ScoresRepository repo,
    required SetlistsRepository setlistsRepo,
    required Iterable<String> selectedScores,
  }) : _repo = repo,
       _setlistsRepo = setlistsRepo,
       _selectedScores = selectedScores.toList();

  void updateSelectedScores(Iterable<String> selectedScores) {
    _selectedScores = selectedScores.toList();
  }

  Future<void> editTags(Set<String> addIds, Set<String> removeIds) async {
    await _repo.bulkEditScoreTags(_selectedScores, addIds, removeIds);
  }

  Future<int> addToSetlist(String setlistId) async {
    final scoreIds = List.of(_selectedScores);
    await _setlistsRepo.addScores(setlistId, scoreIds);
    return scoreIds.length;
  }
}
