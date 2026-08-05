/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
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

  final List<String> _selectedScoreIds = [];
  final Set<String> _selectedScoreIdSet = {};

  List<String> get selectedScoreIds => UnmodifiableListView(_selectedScoreIds);

  Set<String> get selectedScoreIdSet =>
      UnmodifiableSetView(_selectedScoreIdSet);

  HomeViewModel({required ScoresRepository scoresRepo})
    : _scoresRepo = scoresRepo;

  @override
  void dispose() {
    importButtonVisible.dispose();
    super.dispose();
  }

  void selectScore(String scoreId) {
    if (!_selectedScoreIdSet.add(scoreId)) return;
    _selectedScoreIds.add(scoreId);
    notifyListeners();
  }

  void deselectScore(String scoreId) {
    if (!_selectedScoreIdSet.remove(scoreId)) return;
    _selectedScoreIds.remove(scoreId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedScoreIds.clear();
    _selectedScoreIdSet.clear();
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

  Future<String?> scanScore() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    _importing = true;
    notifyListeners();
    try {
      final pdfPath = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.camera,
        asPdf: true,
      );
      if (pdfPath == null || pdfPath.isEmpty) return null;

      try {
        final scores = await _scoresRepo.importAll(
          pdfPath.map((p) => XFile(p, mimeType: "application/pdf")),
        );
        return scores.first.id;
      } finally {
        await CunningDocumentScanner.cleanCache();
      }
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
