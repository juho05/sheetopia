import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class LibraryViewModel extends ChangeNotifier {
  final ScoresRepository _repo;

  List<Score> _scores = [];
  UnmodifiableListView<Score> get scores => UnmodifiableListView(_scores);

  StreamSubscription? _updatedScoresSub;
  LibraryViewModel({required ScoresRepository repo}) : _repo = repo {
    _load().then((value) {
      _updatedScoresSub = _repo.updatedScores.listen((_) => _load());
    });
  }

  Future<void> _load() async {
    _scores = await _repo.getAllScores();
    notifyListeners();
  }

  @override
  void dispose() {
    _updatedScoresSub?.cancel();
    super.dispose();
  }
}
