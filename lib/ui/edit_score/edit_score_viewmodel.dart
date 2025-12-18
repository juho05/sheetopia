import 'dart:async';
import 'dart:collection';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class EditScoreViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  Score? _score;
  Score? get score => _score;

  StreamSubscription? _updatedScoresSub;

  late final Queue<String> _freshImports;
  bool get hasNext => _freshImports.isNotEmpty;

  late final bool isImport;

  EditScoreViewModel({required ScoresRepository repo, required scoreId})
    : _repo = repo {
    isImport = _repo.freshImports.isNotEmpty;
    _freshImports = Queue.of(_repo.freshImports.where((id) => id != scoreId));
    _repo.clearFreshImports();

    _load(scoreId).then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => s.any((id) => id == scoreId))
          .listen((_) => _load(scoreId));
    });
  }

  Future<void> _load(String scoreId) async {
    final score = await _repo.getScore(scoreId);
    _score = score;
    // TODO properly handle score == null
    notifyListeners();
  }

  Future<void> edit({required String title}) async {
    await _repo.updateScore(score!.id, title: title);
  }

  Future<void> changeFile() async {
    final XFile? file = await openFile(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Select",
    );
    if (file == null) return;
    await _repo.updateScoreFile(score!.id, file.path);
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

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    super.dispose();
  }
}
