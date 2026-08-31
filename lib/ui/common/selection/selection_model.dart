/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:flutter/foundation.dart';

class SelectionModel extends ChangeNotifier {
  final List<String> _ids = [];
  final Set<String> _idSet = {};

  List<String> get ids => UnmodifiableListView(_ids);

  Set<String> get idSet => UnmodifiableSetView(_idSet);

  int get length => _ids.length;

  bool get isEmpty => _ids.isEmpty;

  bool get isNotEmpty => _ids.isNotEmpty;

  bool contains(String id) => _idSet.contains(id);

  void select(String id) {
    if (!_idSet.add(id)) return;
    _ids.add(id);
    notifyListeners();
  }

  void selectAll(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (!_idSet.add(id)) continue;
      _ids.add(id);
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
  }

  void deselect(String id) {
    if (!_idSet.remove(id)) return;
    _ids.remove(id);
    notifyListeners();
  }

  void toggle(String id) => contains(id) ? deselect(id) : select(id);

  void clear() {
    if (_ids.isEmpty) return;
    _ids.clear();
    _idSet.clear();
    notifyListeners();
  }
}
