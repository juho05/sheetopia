/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/file_picker.dart';

class HomeViewModel extends ChangeNotifier {
  final ScoresRepository _scoresRepo;

  bool _importing = false;

  bool get importing => _importing;

  final ValueNotifier<bool> importButtonVisible = ValueNotifier(true);

  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  set tabIndex(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  bool _dragging = false;

  bool get dragging => _dragging;

  set dragging(bool dragging) {
    if (_dragging == dragging) return;
    _dragging = dragging;
    notifyListeners();
  }

  final Set<String> _selectedScoreIds = {};

  Set<String> get selectedScoreIds => UnmodifiableSetView(_selectedScoreIds);

  HomeViewModel({required ScoresRepository scoresRepo})
    : _scoresRepo = scoresRepo;

  @override
  void dispose() {
    importButtonVisible.dispose();
    super.dispose();
  }

  void selectScore(String scoreId) {
    _selectedScoreIds.add(scoreId);
    notifyListeners();
  }

  void deselectScore(String scoreId) {
    _selectedScoreIds.remove(scoreId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedScoreIds.clear();
    notifyListeners();
  }

  Future<String?> importScores() async {
    _importing = true;
    notifyListeners();
    try {
      final files = await selectScoreFiles();
      if (files.isEmpty) return null;

      final scores = await _scoresRepo.importAll(files);
      return scores.first.id;
    } finally {
      _importing = false;
      notifyListeners();
    }
  }

  Future<String?> receiveDrop(DropDoneDetails details) async {
    _importing = true;
    notifyListeners();
    try {
      final scores = await _scoresRepo.importAll(details.files);
      if (scores.isEmpty) return null;
      return scores.first.id;
    } finally {
      _importing = false;
      notifyListeners();
    }
  }
}
