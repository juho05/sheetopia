/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

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

  late final Queue<String> _freshImports;

  bool get hasNext => _freshImports.isNotEmpty;

  late final bool isImport;

  EditScoreViewModel({required this._repo, required scoreId}) {
    isImport = _repo.freshImports.isNotEmpty;
    _freshImports = Queue.of(_repo.freshImports.where((id) => id != scoreId));
    _repo.clearFreshImports();

    _load(scoreId).then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => s.contains(_score?.id))
          .listen((_) => _load(scoreId));
    });
  }

  Future<void> _load(String scoreId) async {
    final score = await _repo.getScore(scoreId);
    _score = score;
    // TODO properly handle score == null
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

    final scoreId = _freshImports.removeFirst();

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
    super.dispose();
  }
}
