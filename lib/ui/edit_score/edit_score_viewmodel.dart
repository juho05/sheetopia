/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/file_picker.dart';
import 'package:sheetopia/utils/score_file.dart';

class EditScoreViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  Score? _score;

  Score? get score => _score;

  StreamSubscription? _updatedScoresSub;

  String? _nextImportId;

  bool get hasNext => _nextImportId != null;

  final bool isImport;

  EditScoreViewModel({
    required this._repo,
    required String? scoreId,
    required this.isImport,
  }) {
    _load(scoreId).then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => _score != null && s.contains(_score!.id))
          .listen((_) => _load(_score!.id));
    });
  }

  Future<void> _load(String? scoreId) async {
    scoreId ??= await _repo.getNextScoreIdThatNeedsEdit();
    if (scoreId == null) return;

    final score = await _repo.getScore(scoreId);
    _score = score;

    if (isImport) {
      _nextImportId = await _repo.getNextScoreIdThatNeedsEdit(skipId: scoreId);
    }

    notifyListeners();
  }

  Future<void> delete() async {
    await _repo.deleteScore(score!.id);
  }

  Future<void> changeFile() async {
    final file = await selectScoreFile();
    if (file == null) return;
    await _repo.updateScoreFile(score!.id, file);
  }

  Future<void> next() async {
    if (!hasNext) return;
    _updatedScoresSub?.cancel();
    _updatedScoresSub = null;
    await _repo.updateScoreStatus([score!.id]);

    final scoreId = _nextImportId!;
    _nextImportId = null;

    await _load(scoreId);
    _updatedScoresSub = _repo.updatedScoreIds
        .where((s) => s.any((id) => id == scoreId))
        .listen((_) => _load(scoreId));
  }

  Future<void> share({Rect? sharePositionOrigin}) async {
    if (score == null) return;
    await shareScoreFile(score!, sharePositionOrigin: sharePositionOrigin);
  }

  Future<bool> save() async {
    if (score == null) return false;
    return exportScoreFile(score!);
  }

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    if (score != null) {
      _repo.updateScoreStatus([score!.id]);
    }
    super.dispose();
  }
}
