/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

typedef ExerciseGroup = ({String? category, List<Exercise> exercise});

class ExercisesViewModel extends ChangeNotifier {
  List<ExerciseGroup> _exercises = [];

  UnmodifiableListView<ExerciseGroup> get exercises =>
      UnmodifiableListView(_exercises);

  ExercisesViewModel() {
    _load();
  }

  String _filterSearch = "";

  set filterSearch(String filter) {
    if (_filterSearch == filter) return;
    _filterSearch = filter;
    _load();
  }

  String _filterCategory = "";

  String get filterCategory => _filterCategory;

  set filterCategory(String category) {
    if (_filterCategory == category) return;
    _filterCategory = category;
    _load();
  }

  String _filterInstrument = "";

  String get filterInstrument => _filterInstrument;

  set filterInstrument(String instrument) {
    if (_filterInstrument == instrument) return;
    _filterInstrument = instrument;
    _load();
  }

  final SplayTreeSet<Tag> _filterTags = SplayTreeSet(
    (a, b) => a.name.compareTo(b.name),
  );

  Iterable<Tag> get filterTags => _filterTags;

  FilterMatchType _tagMatch = FilterMatchType.all;

  FilterMatchType get tagMatch => _tagMatch;

  set tagMatch(FilterMatchType value) {
    if (_tagMatch == value) return;
    _tagMatch = value;
    _load();
  }

  bool get hasFilters =>
      _filterCategory.isNotEmpty ||
      _filterInstrument.isNotEmpty ||
      _filterTags.isNotEmpty;

  bool get isFiltered => _filterSearch.isNotEmpty || hasFilters;

  void addFilterTags(Iterable<Tag> tags) {
    _filterTags.addAll(tags);
    notifyListeners();
    _load();
  }

  void removeFilterTag(Tag tag) {
    _filterTags.remove(tag);
    notifyListeners();
    _load();
  }

  void clearFilters() {
    if (!hasFilters) return;
    _filterCategory = "";
    _filterInstrument = "";
    _filterTags.clear();
    _tagMatch = FilterMatchType.all;
    _load();
  }

  // TODO
  Future<Iterable<String>> getCategories({String filter = ""}) async => [];

  // TODO
  Future<Iterable<String>> getInstruments({String filter = ""}) async => [];

  // TODO support pagination
  // TODO load from repository including filters
  Future<void> _load() async {
    _exercises = [
      (
        category: "Warmup",
        exercise: [
          Exercise(
            name: "Test asdf",
            category: const ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: "Guitar",
            tags: [
              Tag(
                id: "",
                name: "Test",
                color: Colors.red,
                updatedAt: DateTime.now(),
              ),
              Tag(
                id: "",
                name: "Test2",
                color: Colors.blue,
                updatedAt: DateTime.now(),
              ),
            ],
          ),
          const Exercise(
            name:
                "Blab lab als asdjb aslh aslkjd hfaskl hfkajs hfkajsh fkjashd asödfjas öflk asöfkj as",
            category: ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: "Guitar",
            tags: [],
          ),
          const Exercise(
            name: "bla",
            category: ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: null,
            tags: [],
          ),
        ],
      ),
      (
        category: null,
        exercise: [
          Exercise(
            name: "Test asdf",
            category: const ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: "Guitar",
            tags: [
              Tag(
                id: "",
                name: "Test",
                color: Colors.red,
                updatedAt: DateTime.now(),
              ),
              Tag(
                id: "",
                name: "Test2",
                color: Colors.blue,
                updatedAt: DateTime.now(),
              ),
            ],
          ),
          const Exercise(
            name:
                "Blab lab als asdjb aslh aslkjd hfaskl hfkajs hfkajsh fkjashd asödfjas öflk asöfkj as",
            category: ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: "Guitar",
            tags: [],
          ),
          const Exercise(
            name: "bla",
            category: ExerciseCategory(name: "Warmup"),
            description: null,
            instrument: null,
            tags: [],
          ),
        ],
      ),
    ];
    notifyListeners();
  }
}
