/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/file_picker.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';

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

  final SelectionModel _selection = SelectionModel();

  List<String> get selectedScoreIds => _selection.ids;

  Set<String> get selectedScoreIdSet => _selection.idSet;

  HomeViewModel({required this._scoresRepo}) {
    _selection.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _selection.dispose();
    importButtonVisible.dispose();
    super.dispose();
  }

  void selectScore(String scoreId) => _selection.select(scoreId);

  void selectScores(Iterable<String> scoreIds) =>
      _selection.selectAll(scoreIds);

  void deselectScore(String scoreId) => _selection.deselect(scoreId);

  void clearSelection() => _selection.clear();

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

  Future<String?> receiveDrop(Iterable<XFile> files) async {
    _importing = true;
    notifyListeners();
    try {
      final scores = await _scoresRepo.importAll(files);
      if (scores.isEmpty) return null;
      return scores.first.id;
    } finally {
      _importing = false;
      notifyListeners();
    }
  }
}
