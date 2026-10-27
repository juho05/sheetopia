/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/musical_key.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';

class BulkEditMenuViewModel {
  List<String> _selectedScores;

  final ScoresRepository _repo;
  final SetlistsRepository _setlistsRepo;

  BulkEditMenuViewModel({
    required this._repo,
    required this._setlistsRepo,
    required Iterable<String> selectedScores,
  }) : _selectedScores = selectedScores.toList();

  void updateSelectedScores(Iterable<String> selectedScores) {
    _selectedScores = selectedScores.toList();
  }

  Future<void> editTags(Set<String> addIds, Set<String> removeIds) async {
    await _repo.bulkEditScoreTags(_selectedScores, addIds, removeIds);
  }

  Future<void> editComposer(String composer) async {
    await _repo.bulkEditScoreComposer(_selectedScores, composer);
  }

  Future<void> editArranger(String arranger) async {
    await _repo.bulkEditScoreArranger(_selectedScores, arranger);
  }

  Future<void> editPartOf(String partOf) async {
    await _repo.bulkEditScorePartOf(_selectedScores, partOf);
  }

  Future<void> editDifficulty(Difficulty? difficulty) async {
    await _repo.bulkEditScoreDifficulty(_selectedScores, difficulty);
  }

  Future<void> editMusicalKey(MusicalKey? musicalKey) async {
    await _repo.bulkEditScoreMusicalKey(_selectedScores, musicalKey);
  }

  Future<void> editSource(String source, String sourceLink) async {
    await _repo.bulkEditScoreSource(_selectedScores, source, sourceLink);
  }

  Future<void> editInstruments(
    Iterable<String> add,
    Iterable<String> remove,
  ) async {
    await _repo.bulkEditScoreInstruments(_selectedScores, add, remove);
  }

  Future<void> editGenres(Iterable<String> add, Iterable<String> remove) async {
    await _repo.bulkEditScoreGenres(_selectedScores, add, remove);
  }

  Future<Iterable<String>> getComposers({String filter = ""}) async {
    return await _repo.getComposers(filter: filter, size: 10);
  }

  Future<Iterable<String>> getArrangers({String filter = ""}) async {
    return await _repo.getArrangers(filter: filter, size: 10);
  }

  Future<Iterable<String>> getPartOfs({String filter = ""}) async {
    return await _repo.getPartOfs(filter: filter, size: 10);
  }

  Future<Iterable<String>> getSources({String filter = ""}) async {
    return await _repo.getSources(filter: filter, size: 10);
  }

  Future<Iterable<String>> getInstruments({
    String filter = "",
    Iterable<String> exclude = const [],
  }) async {
    return await _repo.getInstruments(
      filter: filter,
      size: 10,
      exclude: exclude,
    );
  }

  Future<Iterable<String>> getGenres({
    String filter = "",
    Iterable<String> exclude = const [],
  }) async {
    return await _repo.getGenres(filter: filter, size: 10, exclude: exclude);
  }

  Future<int> delete() async {
    final scoreIds = _selectedScores.toSet();
    await _repo.deleteScores(scoreIds);
    return scoreIds.length;
  }

  Future<int> addToSetlist(String setlistId) async {
    final scoreIds = List.of(_selectedScores);
    await _setlistsRepo.addScores(setlistId, scoreIds);
    return scoreIds.length;
  }
}
