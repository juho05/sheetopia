/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';

class CategorySync {
  final PracticeRepository _repo;
  final ExerciseCategory? Function() _currentCategory;
  final void Function(ExerciseCategory? category) _onChanged;

  StreamSubscription? _sub;

  CategorySync({
    required this._repo,
    required this._currentCategory,
    required this._onChanged,
  }) {
    _sub = _repo.updatedCategoryIds.listen(_onUpdatedCategories);
  }

  Future<void> _onUpdatedCategories(Set<String> updatedIds) async {
    final current = _currentCategory();
    if (current == null) return;
    if (updatedIds.isNotEmpty && !updatedIds.contains(current.id)) return;
    await sync();
  }

  Future<void> sync() async {
    final current = _currentCategory();
    if (current == null) return;
    final loaded = await _repo.getCategory(current.id);
    if (_sub == null || _currentCategory()?.id != current.id) return;
    if (loaded != null && loaded.name == _currentCategory()!.name) return;
    _onChanged(loaded);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
