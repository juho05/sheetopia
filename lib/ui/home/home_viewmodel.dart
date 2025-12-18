import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final ScoresRepository _scoresRepo;

  HomeViewModel({required ScoresRepository scoresRepo})
    : _scoresRepo = scoresRepo;

  Future<String?> importScores() async {
    final List<XFile> files = await openFiles(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Import",
    );
    if (files.isEmpty) return null;

    final scores = await _scoresRepo.importAll(files.map((f) => f.path));
    return scores.first.id;
  }
}
