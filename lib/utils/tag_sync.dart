/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

class TagSync {
  final ScoresRepository _repo;
  final Iterable<Tag> Function() _currentTags;
  final void Function(List<Tag> tags) _onChanged;

  StreamSubscription? _sub;

  TagSync({
    required this._repo,
    required this._currentTags,
    required this._onChanged,
  }) {
    _sub = _repo.updatedTagIds.listen(_onUpdatedTags);
  }

  Future<void> _onUpdatedTags(Set<String> updatedIds) async {
    if (updatedIds.isNotEmpty &&
        !_currentTags().any((t) => updatedIds.contains(t.id))) {
      return;
    }
    await sync();
  }

  Future<void> sync() async {
    final loadedIds = _currentTags().map((t) => t.id).toSet();
    if (loadedIds.isEmpty) return;
    final loaded = {
      for (final t in await _repo.getTagsById(loadedIds)) t.id: t,
    };

    // the selection can have changed while loading, so only tags that were
    // loaded are replaced or dropped
    final current = _currentTags().toList();
    final tags = [
      for (final t in current)
        if (loaded.containsKey(t.id))
          loaded[t.id]!
        else if (!loadedIds.contains(t.id))
          t,
    ];
    if (_unchanged(current, tags)) return;
    _onChanged(tags);
  }

  static bool _unchanged(List<Tag> current, List<Tag> updated) {
    if (current.length != updated.length) return false;
    final byId = {for (final t in current) t.id: t};
    return updated.every((t) {
      final c = byId[t.id];
      return c != null && c.name == t.name && c.color == t.color;
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
