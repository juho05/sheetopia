/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

mixin FilterViewModel on ChangeNotifier {
  void refilter();

  bool get hasOwnFilters;

  void clearOwnFilters();

  String _filterSearch = "";

  String get filterSearch => _filterSearch;

  set filterSearch(String filter) {
    if (_filterSearch == filter) return;
    _filterSearch = filter;
    refilter();
  }

  String _filterSource = "";

  String get filterSource => _filterSource;

  set filterSource(String source) {
    if (_filterSource == source) return;
    _filterSource = source;
    notifyListeners();
    refilter();
  }

  final Set<Difficulty?> _filterDifficulties = {};

  Set<Difficulty?> get filterDifficulties => _filterDifficulties;

  void toggleFilterDifficulty(Difficulty? difficulty, bool selected) {
    final changed = selected
        ? _filterDifficulties.add(difficulty)
        : _filterDifficulties.remove(difficulty);
    if (!changed) return;
    notifyListeners();
    refilter();
  }

  void clearFilterDifficulties() {
    if (_filterDifficulties.isEmpty) return;
    _filterDifficulties.clear();
    notifyListeners();
    refilter();
  }

  final SplayTreeSet<Tag> _filterTags = SplayTreeSet(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  Iterable<Tag> get filterTags => _filterTags;

  FilterMatchType _tagMatch = FilterMatchType.all;

  FilterMatchType get tagMatch => _tagMatch;

  set tagMatch(FilterMatchType value) {
    if (_tagMatch == value) return;
    _tagMatch = value;
    notifyListeners();
    refilter();
  }

  void addFilterTags(Iterable<Tag> tags) {
    _filterTags.addAll(tags);
    notifyListeners();
    refilter();
  }

  void removeFilterTag(Tag tag) {
    _filterTags.remove(tag);
    notifyListeners();
    refilter();
  }

  void setFilterTags(Iterable<Tag> tags) {
    _filterTags
      ..clear()
      ..addAll(tags);
    notifyListeners();
    refilter();
  }

  bool get hasFilters =>
      _filterSource.isNotEmpty ||
      _filterDifficulties.isNotEmpty ||
      _filterTags.isNotEmpty ||
      hasOwnFilters;

  bool get isFiltered => _filterSearch.isNotEmpty || hasFilters;

  void clearFilters() {
    if (!hasFilters) return;
    _filterSource = "";
    _filterDifficulties.clear();
    _filterTags.clear();
    _tagMatch = FilterMatchType.all;
    clearOwnFilters();
    notifyListeners();
    refilter();
  }
}
