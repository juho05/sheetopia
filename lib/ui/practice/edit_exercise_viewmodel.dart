/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/file_picker.dart';

class ExerciseScoreEntry {
  final int id;
  final Score score;

  const ExerciseScoreEntry({required this.id, required this.score});

  ExerciseScoreEntry withScore(Score score) =>
      ExerciseScoreEntry(id: id, score: score);
}

class EditExerciseViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  final ScoresRepository _scoresRepo;

  final String? _exerciseId;

  String? get exerciseId => _exerciseId;

  final bool isCreate;

  bool _loading;

  bool get loading => _loading;

  SplayTreeSet<Tag> _tags = SplayTreeSet(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  Iterable<Tag> get tags => _tags;

  ExerciseCategory? _category;

  ExerciseCategory? get category => _category;

  String? _source;

  String? get source => _source;

  String? _sourceLink;

  String? get sourceLink => _sourceLink;

  final FormGroup form;

  static const String formName = "name";
  static const String formDescription = "description";
  static const String formInstrument = "instrument";

  String get name => _formValue(formName);

  StreamSubscription? _valueSub;

  List<ExerciseScoreEntry> _scoreEntries = [];

  UnmodifiableListView<ExerciseScoreEntry> get scoreEntries =>
      UnmodifiableListView(_scoreEntries);

  int _nextEntryId = 0;

  bool _scoresLoading = false;

  bool get scoresLoading => _scoresLoading;

  bool _created = false;

  EditExerciseViewModel({
    required this._repo,
    required this._scoresRepo,
    required this._exerciseId,
  }) : isCreate = _exerciseId == null,
       _loading = _exerciseId != null,
       form = FormGroup({
         formName: FormControl<String>(validators: [Validators.required]),
         formDescription: FormControl<String>(),
         formInstrument: FormControl<String>(),
       }) {
    _load().then((_) {
      _valueSub = form.valueChanges.listen((_) {
        if (form.invalid) return;
        _onValuesChanged();
      });
    });
  }

  Future<void> setCategory(ExerciseCategory? category) async {
    _category = category;
    notifyListeners();
    if (_exerciseId == null) return;
    await _repo.updateExerciseCategory(_exerciseId, category?.id);
  }

  Future<void> setSource(String source, String sourceLink) async {
    _source = source.isNotEmpty ? source : null;
    _sourceLink = _source != null && sourceLink.isNotEmpty ? sourceLink : null;
    notifyListeners();
    if (_exerciseId == null) return;
    await _repo.updateExerciseSource(
      _exerciseId,
      source: source,
      sourceLink: sourceLink,
    );
  }

  Future<void> linkScores(Iterable<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    _scoresLoading = true;
    notifyListeners();
    final linked = await _loadScores(scoreIds);
    _scoreEntries.addAll(linked);
    _scoresLoading = false;
    notifyListeners();
    await _persistExerciseScores();
  }

  Future<void> importScores() async {
    _scoresLoading = true;
    notifyListeners();
    try {
      final files = await selectScoreFiles();
      if (files.isEmpty) return;

      final scores = await _scoresRepo.importAll(
        files,
        type: ScoreType.exercise,
      );
      _scoreEntries.addAll(_toEntries(scores));
      notifyListeners();
      await _persistExerciseScores();
    } finally {
      _scoresLoading = false;
      notifyListeners();
    }
  }

  Future<void> moveScore(int from, int to) async {
    if (from == to) return;
    _scoreEntries.insert(to, _scoreEntries.removeAt(from));
    notifyListeners();
    await _persistExerciseScores();
  }

  Future<void> removeScore(int entryId) async {
    final index = _scoreEntries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;
    final score = _scoreEntries.removeAt(index).score;
    final stillLinked = _scoreEntries.any((e) => e.score.id == score.id);
    if (!stillLinked) {
      _scoreTitleDebounce.remove(score.id)?.cancel();
    }
    notifyListeners();
    await _persistExerciseScores();
    if (_exerciseId == null &&
        !stillLinked &&
        score.type == ScoreType.exercise) {
      await _scoresRepo.deleteScore(score.id);
    }
  }

  void setScoreTitle(String scoreId, String title) {
    var changed = false;
    for (final (i, e) in _scoreEntries.indexed) {
      if (e.score.id != scoreId || e.score.title == title) continue;
      _scoreEntries[i] = e.withScore(e.score.copyWith(title: title));
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _scoreTitleDebounce[scoreId]?.cancel();
    _scoreTitleDebounce[scoreId] = Timer(
      _valuesDebounceDuration,
      () => _saveScoreTitle(scoreId),
    );
  }

  Future<void> _saveScoreTitle(String scoreId) async {
    if (_scoreTitleDebounce.remove(scoreId) == null) return;
    final index = _scoreEntries.indexWhere((e) => e.score.id == scoreId);
    if (index == -1) return;
    final title = _scoreEntries[index].score.title.trim();
    if (title.isEmpty) return;
    await _scoresRepo.updateScoreTitle(scoreId, title);
  }

  Future<void> _saveScoreTitles() async {
    for (final timer in _scoreTitleDebounce.values) {
      timer.cancel();
    }
    await Future.wait(_scoreTitleDebounce.keys.toList().map(_saveScoreTitle));
  }

  Future<void> _persistExerciseScores() async {
    if (_exerciseId == null) return;
    await _repo.setExerciseScores(
      _exerciseId,
      _scoreEntries.map((e) => e.score.id).toList(),
    );
  }

  Future<List<ExerciseScoreEntry>> _loadScores(
    Iterable<String> scoreIds,
  ) async {
    final scores = await Future.wait(scoreIds.map(_scoresRepo.getScore));
    return _toEntries(scores.nonNulls);
  }

  List<ExerciseScoreEntry> _toEntries(Iterable<Score> scores) => scores
      .map((s) => ExerciseScoreEntry(id: _nextEntryId++, score: s))
      .toList();

  Future<void> addTags(Iterable<Tag> tags) async {
    _tags.addAll(tags);
    notifyListeners();
    if (_exerciseId == null) return;
    await _repo.addExerciseTags(_exerciseId, tags.map((t) => t.id));
  }

  Future<void> removeTag(Tag tag) async {
    _tags.remove(tag);
    notifyListeners();
    if (_exerciseId == null) return;
    await _repo.removeExerciseTag(_exerciseId, tag.id);
  }

  List<String>? _instruments;

  Future<Iterable<String>> getInstruments({String filter = ""}) async {
    _instruments ??= await _repo.getInstruments();
    filter = filter.toLowerCase();
    return _instruments!
        .where((element) => element.toLowerCase().contains(filter))
        .take(10);
  }

  List<String>? _sources;

  Future<Iterable<String>> getSources({String filter = ""}) async {
    _sources ??= await _repo.getSources();
    filter = filter.toLowerCase();
    return _sources!
        .where((element) => element.toLowerCase().contains(filter))
        .take(10);
  }

  Future<void> create() async {
    if (form.invalid) {
      throw StateError("Only call create when the form is valid!");
    }
    _created = true;
    await _repo.createExercise(
      name: name,
      description: _formValue(formDescription),
      instrument: _formValue(formInstrument),
      source: _source ?? "",
      sourceLink: _sourceLink ?? "",
      tagIds: _tags.map((t) => t.id),
      scoreIds: _scoreEntries.map((e) => e.score.id),
      categoryId: _category?.id,
    );
  }

  Future<void> delete() async {
    if (_exerciseId == null) return;
    _valuesDebounce?.cancel();
    _valuesDebounce = null;
    for (final timer in _scoreTitleDebounce.values) {
      timer.cancel();
    }
    _scoreTitleDebounce.clear();
    await _repo.deleteExercise(_exerciseId);
  }

  Future<void> reloadExercise() async {
    if (_exerciseId == null) return;
    await _saveValues();
    await _saveScoreTitles();
    await _load();
  }

  Future<void> _load() async {
    if (_exerciseId == null) return;
    _instruments = null;
    _sources = null;
    final exercise = await _repo.getExercise(_exerciseId);
    // TODO properly handle exercise == null
    if (exercise != null) {
      _category = exercise.category;
      _source = exercise.source;
      _sourceLink = exercise.sourceLink;
      _tags = SplayTreeSet.of(
        exercise.tags,
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      form.updateValue({
        formName: exercise.name,
        formDescription: exercise.description,
        formInstrument: exercise.instrument ?? "",
      }, emitEvent: false);
      _scoreEntries = await _loadScores(
        await _repo.getExerciseScoreIds(_exerciseId),
      );
    }
    _loading = false;
    notifyListeners();
  }

  Timer? _valuesDebounce;
  final Map<String, Timer> _scoreTitleDebounce = {};
  static const _valuesDebounceDuration = Duration(milliseconds: 250);

  void _onValuesChanged() {
    if (_exerciseId == null) return;
    _valuesDebounce?.cancel();
    _valuesDebounce = Timer(_valuesDebounceDuration, _saveValues);
  }

  Future<void> _saveValues() async {
    if (_valuesDebounce == null) return;
    _valuesDebounce!.cancel();
    _valuesDebounce = null;
    await _repo.updateExercise(
      _exerciseId!,
      name: name,
      description: _formValue(formDescription),
      instrument: _formValue(formInstrument),
    );
  }

  String _formValue(String control) =>
      (form.control(control).value as String? ?? "").trim();

  Future<void> _discardImports() async {
    for (final timer in _scoreTitleDebounce.values) {
      timer.cancel();
    }
    _scoreTitleDebounce.clear();
    final owned = _scoreEntries
        .where((e) => e.score.type == ScoreType.exercise)
        .map((e) => e.score.id)
        .toSet();
    _scoreEntries.clear();
    await _scoresRepo.deleteScores(owned);
  }

  @override
  void dispose() {
    _saveValues();
    if (_exerciseId == null && !_created) {
      _discardImports();
    } else {
      _saveScoreTitles();
    }
    _valueSub?.cancel();
    super.dispose();
  }
}
