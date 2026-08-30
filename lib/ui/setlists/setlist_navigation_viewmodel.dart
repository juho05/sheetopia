/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlist.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';

class SetlistNavigationViewModel extends ChangeNotifier
    implements ScoreSequence {
  final SetlistsRepository _repo;
  final ScoresRepository _scoresRepo;

  Setlist _setlist;

  int _index;

  bool _deleted = false;

  StreamSubscription? _setlistSub;
  StreamSubscription? _scoresSub;

  SetlistNavigationViewModel(
    this._setlist, {
    required this._repo,
    required this._scoresRepo,
    int? startIndex,
  }) : _index = startIndex ?? _setlist.entries.indexWhere((e) => e.playable) {
    _setlistSub = _repo.updatedSetlistIds
        .where((ids) => ids.contains(_setlist.id))
        .listen((_) => _reload());
    _scoresSub = _scoresRepo.updatedScoreIds
        .where((ids) => ids.any(_scoreIds.contains))
        .listen((_) => _reload());
  }

  Setlist get setlist => _setlist;

  @override
  int get position => _index;

  int get length => _setlist.entries.length;

  String get name => _setlist.name;

  @override
  bool get deleted => _deleted;

  List<SetlistEntry> get entries => _setlist.entries;

  SetlistEntry? get currentEntry =>
      _index < 0 || _index >= _setlist.entries.length
      ? null
      : _setlist.entries[_index];

  @override
  String? get currentScoreId => currentEntry?.scoreId;

  Set<String> get _scoreIds => _setlist.entries.map((e) => e.scoreId).toSet();

  SetlistEntry? get nextPlayableEntry {
    final next = _nextPlayable();
    return next == null ? null : _setlist.entries[next];
  }

  SetlistEntry? get previousPlayableEntry {
    final previous = _previousPlayable();
    return previous == null ? null : _setlist.entries[previous];
  }

  @override
  File? get nextFile => nextPlayableEntry?.score?.file;

  @override
  File? get previousFile => previousPlayableEntry?.score?.file;

  @override
  bool next() {
    final next = _nextPlayable();
    if (next == null) return false;
    _index = next;
    notifyListeners();
    return true;
  }

  @override
  bool previous() {
    final previous = _previousPlayable();
    if (previous == null) return false;
    _index = previous;
    notifyListeners();
    return true;
  }

  void jumpTo(int index) {
    if (index < 0 || index >= _setlist.entries.length) return;
    if (!_setlist.entries[index].playable) return;
    _index = index;
    notifyListeners();
  }

  int? _nextPlayable() {
    for (var i = _index + 1; i < _setlist.entries.length; i++) {
      if (_setlist.entries[i].playable) return i;
    }
    return null;
  }

  int? _previousPlayable() {
    for (var i = _index - 1; i >= 0; i--) {
      if (_setlist.entries[i].playable) return i;
    }
    return null;
  }

  Future<void> _reload() async {
    final setlist = await _repo.getSetlist(_setlist.id);
    if (setlist == null) {
      _deleted = true;
      notifyListeners();
      return;
    }
    final oldIds = _setlist.entries.map((e) => e.scoreId).toList();
    final newIds = setlist.entries.map((e) => e.scoreId).toList();
    final oldScoreId = currentScoreId;
    final oldIndex = _index;

    _setlist = setlist;

    if (listEquals(oldIds, newIds)) {
      // resolution-only: indices cannot have moved, so the score on screen
      // must not either
      if (_index < 0) {
        _index = setlist.entries.indexWhere((e) => e.playable);
      }
    } else {
      _reanchor(oldScoreId, oldIndex);
    }
    notifyListeners();
  }

  void _reanchor(String? oldScoreId, int oldIndex) {
    final entries = _setlist.entries;
    if (entries.isEmpty) {
      _index = -1;
      return;
    }
    if (oldScoreId != null) {
      final i = entries.indexWhere((e) => e.scoreId == oldScoreId);
      if (i >= 0) {
        _index = i;
        return;
      }
    }
    final start = oldIndex < 0 ? 0 : oldIndex.clamp(0, entries.length - 1);
    for (var i = start; i < entries.length; i++) {
      if (entries[i].playable) {
        _index = i;
        return;
      }
    }
    for (var i = start - 1; i >= 0; i--) {
      if (entries[i].playable) {
        _index = i;
        return;
      }
    }
    _index = -1;
  }

  @override
  void dispose() {
    _setlistSub?.cancel();
    _scoresSub?.cancel();
    super.dispose();
  }
}
