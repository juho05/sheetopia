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

class CategorySelectorViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  List<ExerciseCategory> _categories = [];

  UnmodifiableListView<ExerciseCategory> get results =>
      UnmodifiableListView(_results);

  List<ExerciseCategory> _results = [];

  bool _loading = true;

  bool get loading => _loading;

  String _filter = "";

  String get filter => _filter;

  set filter(String filter) {
    if (_filter == filter) return;
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  StreamSubscription? _updatedCategoriesSub;

  CategorySelectorViewModel({required this._repo}) {
    _updatedCategoriesSub = _repo.updatedCategoryIds.listen((_) => load());
    load();
  }

  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    final categories = await _repo.getAllCategories();
    if (generation != _generation) return;
    _categories = categories;
    _applyFilter();
    _loading = false;
    notifyListeners();
  }

  void _applyFilter() {
    final filter = _filter.trim().toLowerCase();
    _results = filter.isEmpty
        ? _categories
        : _categories
              .where((c) => c.name.toLowerCase().contains(filter))
              .toList();
  }

  bool nameTaken(String name) {
    final lower = name.toLowerCase();
    return _categories.any((c) => c.name.toLowerCase() == lower);
  }

  Future<ExerciseCategory> create(String name) => _repo.createCategory(name);

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _updatedCategoriesSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
