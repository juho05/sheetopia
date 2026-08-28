/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';

typedef CategoryEntry = ({ExerciseCategory category, int exerciseCount});

class ManageCategoriesViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  List<CategoryEntry> _categories = [];

  UnmodifiableListView<CategoryEntry> get categories =>
      UnmodifiableListView(_categories);

  bool _loading = true;

  bool get loading => _loading;

  StreamSubscription? _updatedCategoriesSub;

  StreamSubscription? _updatedExercisesSub;

  ManageCategoriesViewModel({required this._repo}) {
    _updatedCategoriesSub = _repo.updatedCategoryIds.listen((_) => load());
    // the exercise counts change with the exercises
    _updatedExercisesSub = _repo.updatedExerciseIds.listen((_) => load());
    load();
  }

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    final categories = await _repo.getAllCategories();
    final counts = await _repo.countExercisesPerCategory();
    if (generation != _generation) return;
    _categories = [
      for (final category in categories)
        (category: category, exerciseCount: counts[category.id] ?? 0),
    ];
    _loading = false;
    notifyListeners();
  }

  bool nameTaken(String name, {String? exceptId}) {
    final lower = name.toLowerCase();
    return _categories.any(
      (e) =>
          e.category.id != exceptId && e.category.name.toLowerCase() == lower,
    );
  }

  Future<void> create(String name) => _repo.createCategory(name);

  Future<void> rename(String categoryId, String name) =>
      _repo.renameCategory(categoryId, name);

  Future<void> delete(String categoryId) => _repo.deleteCategory(categoryId);

  Future<void> move(int from, int to) async {
    if (from == to) return;
    final categories = List.of(_categories);
    categories.insert(to, categories.removeAt(from));
    _categories = categories;
    notifyListeners();
    await _repo.moveCategory(from, to);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _updatedCategoriesSub?.cancel();
    _updatedExercisesSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
