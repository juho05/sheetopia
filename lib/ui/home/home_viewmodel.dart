import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/file_picker.dart';

class HomeViewModel extends ChangeNotifier {
  final ScoresRepository _scoresRepo;

  bool _importing = false;
  bool get importing => _importing;

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
