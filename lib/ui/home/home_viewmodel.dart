/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/file_picker.dart';

class HomeViewModel extends ChangeNotifier {
  final ScoresRepository _scoresRepo;

  bool _importing = false;
  bool get importing => _importing;

  bool _importButtonVisible = true;
  bool get importButtonVisible => _importButtonVisible;
  set importButtonVisible(bool visible) {
    if (_importButtonVisible == visible) return;
    _importButtonVisible = visible;
    notifyListeners();
  }

  HomeViewModel({required ScoresRepository scoresRepo})
    : _scoresRepo = scoresRepo;

  Future<String?> importScores() async {
    _importing = true;
    notifyListeners();
    try {
      final files = await selectScoreFiles();
      if (files.isEmpty) return null;

      final scores = await _scoresRepo.importAll(files.map((f) => f.path));
      return scores.first.id;
    } finally {
      _importing = false;
      notifyListeners();
    }
  }
}
