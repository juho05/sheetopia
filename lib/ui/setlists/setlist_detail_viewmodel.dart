/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/setlists/setlist.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';

class SetlistDetailViewModel extends ChangeNotifier {
  final SetlistsRepository _repo;
  final String setlistId;

  Setlist? _setlist;
  bool _loading = true;
  bool _deleted = false;

  StreamSubscription? _updatedSub;

  Setlist? get setlist => _setlist;

  bool get loading => _loading;

  bool get deleted => _deleted;

  List<SetlistEntry> get entries => _setlist?.entries ?? const [];

  SetlistDetailViewModel({
    required SetlistsRepository repo,
    required this.setlistId,
  }) : _repo = repo {
    _updatedSub = _repo.updatedSetlistIds
        .where((ids) => ids.contains(setlistId))
        .listen((_) => load());
    load();
  }

  Future<void> load() async {
    final setlist = await _repo.getSetlist(setlistId);
    _loading = false;
    if (setlist == null) {
      _deleted = true;
      notifyListeners();
      return;
    }
    _setlist = setlist;
    notifyListeners();
  }

  Future<void> rename(String name) => _repo.renameSetlist(setlistId, name);

  Future<void> addScores(List<String> scoreIds) =>
      _repo.addScores(setlistId, scoreIds);

  Future<void> moveEntry(int from, int to) async {
    _applyLocally((entries) => entries.insert(to, entries.removeAt(from)));
    await _repo.moveEntry(setlistId, from, to);
  }

  Future<void> removeEntry(int index) async {
    _applyLocally((entries) => entries.removeAt(index));
    await _repo.removeEntry(setlistId, index);
  }

  void _applyLocally(void Function(List<SetlistEntry> entries) mutate) {
    final setlist = _setlist;
    if (setlist == null) return;
    final entries = List.of(setlist.entries);
    mutate(entries);
    _setlist = Setlist(
      id: setlist.id,
      name: setlist.name,
      updatedAt: setlist.updatedAt,
      entryCount: entries.length,
      entries: entries,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _updatedSub?.cancel();
    super.dispose();
  }
}
