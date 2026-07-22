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

class SetlistsViewModel extends ChangeNotifier {
  final SetlistsRepository _repo;

  List<Setlist> _setlists = [];
  bool _loading = true;

  StreamSubscription? _updatedSub;

  List<Setlist> get setlists => _setlists;

  bool get loading => _loading;

  SetlistsViewModel({required SetlistsRepository repo}) : _repo = repo {
    _updatedSub = _repo.updatedSetlistIds.listen((_) => load());
    load();
  }

  Future<void> load() async {
    _setlists = await _repo.getSetlists();
    _loading = false;
    notifyListeners();
  }

  Future<void> rename(String id, String name) => _repo.renameSetlist(id, name);

  Future<void> delete(String id) => _repo.deleteSetlist(id);

  @override
  void dispose() {
    _updatedSub?.cancel();
    super.dispose();
  }
}
