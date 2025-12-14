import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class ScoreViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  final String _scoreId;

  Score? _score;

  File? get file => _score?.file;

  FileType? get fileType => _score?.fileType;

  StreamSubscription? _updatedScoresSub;
  ScoreViewModel({required ScoresRepository repo, required String scoreId})
    : _repo = repo,
      _scoreId = scoreId {
    _load().then((_) {
      _updatedScoresSub = _repo.updatedScores
          .where((ss) => ss.any((s) => s.id == _scoreId))
          .listen((_) {
            _load();
          });
    });
  }

  Future<void> _load() async {
    final score = await _repo.getScore(_scoreId);
    _score = score;
    // TODO properly handle score == null
    notifyListeners();
  }

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    super.dispose();
  }
}
