/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/file_picker.dart';
import 'package:sheetopia/ui/common/metadata_form_viewmodel.dart';
import 'package:sheetopia/ui/practice/exercise_field.dart';
import 'package:sheetopia/utils/category_sync.dart';

class ExerciseScoreEntry {
  final int id;
  final Score score;

  const ExerciseScoreEntry({required this.id, required this.score});

  ExerciseScoreEntry withScore(Score score) =>
      ExerciseScoreEntry(id: id, score: score);
}

class EditExerciseViewModel extends ChangeNotifier
    with MetadataFormViewModel<ExerciseField> {
  final PracticeRepository _repo;

  final ScoresRepository _scoresRepo;

  final String? _exerciseId;

  String? get exerciseId => _exerciseId;

  final bool isCreate;

  bool _loading;

  bool get loading => _loading;

  ExerciseCategory? _category;

  ExerciseCategory? get category => _category;

  @override
  List<ExerciseField> get optionalFields => ExerciseField.formOptional;

  @override
  final FormGroup form;

  static const String formName = "name";
  static const String formDescription = "description";
  static const String formInstrument = "instrument";
  static const String formSource = MetadataFormViewModel.formSource;

  String get name => formValue(formName);

  late final instrumentOptions = CachedOptions(_repo.getInstruments);
  late final sourceOptions = CachedOptions(_repo.getSources);

  late final CategorySync _categorySync;

  List<ExerciseScoreEntry> _scoreEntries = [];

  UnmodifiableListView<ExerciseScoreEntry> get scoreEntries =>
      UnmodifiableListView(_scoreEntries);

  int _nextEntryId = 0;

  bool _scoresLoading = false;

  bool get scoresLoading => _scoresLoading;

  bool _created = false;

  bool _creating = false;

  final bool _separate;

  bool _hasNext = false;

  bool get hasNext => _hasNext;

  EditExerciseViewModel({
    required this._repo,
    required this._scoresRepo,
    required this._exerciseId,
    required this._separate,
  }) : isCreate = _exerciseId == null,
       _loading = _exerciseId != null,
       form = FormGroup({
         formName: FormControl<String>(validators: [Validators.required]),
         formDescription: FormControl<String>(),
         formInstrument: FormControl<String>(),
         formSource: FormControl<String>(),
       }) {
    _categorySync = CategorySync(
      repo: _repo,
      currentCategory: () => _category,
      onChanged: (category) {
        _category = category;
        notifyListeners();
      },
    );
    Future<void> load;
    if (_exerciseId == null) {
      load = _loadCreateScores();
    } else {
      load = _load();
    }
    load.then((_) => listenToValues());
  }

  Future<void> setCategory(ExerciseCategory? category) async {
    _category = category;
    notifyListeners();
    if (_exerciseId == null) return;
    await _repo.updateExerciseCategory(_exerciseId, category?.id);
  }

  @override
  Future<void> clearField(ExerciseField field) async {
    switch (field) {
      case ExerciseField.source:
        await setSource("", "");
      case ExerciseField.difficulty:
        await setDifficulty(null);
      case ExerciseField.category ||
          ExerciseField.instrument ||
          ExerciseField.description ||
          ExerciseField.tags:
        break;
    }
  }

  @override
  bool isFilled(ExerciseField field) => switch (field) {
    ExerciseField.source => hasSource,
    ExerciseField.difficulty => difficulty != null,
    _ => false,
  };

  @override
  bool get canPersist => _exerciseId != null;

  @override
  Future<void> persistValues() => _repo.updateExercise(
    _exerciseId!,
    name: name,
    description: formValue(formDescription),
    instrument: formValue(formInstrument),
  );

  @override
  Future<void> persistSource(String source, String sourceLink) =>
      _repo.updateExerciseSource(
        _exerciseId!,
        source: source,
        sourceLink: sourceLink,
      );

  @override
  Future<void> persistDifficulty(Difficulty? difficulty) =>
      _repo.updateExerciseDifficulty(_exerciseId!, difficulty);

  @override
  Future<void> persistAddTags(Iterable<Tag> tags) =>
      _repo.addExerciseTags(_exerciseId!, tags.map((t) => t.id));

  @override
  Future<void> persistRemoveTag(Tag tag) =>
      _repo.removeExerciseTag(_exerciseId!, tag.id);

  Future<void> linkScoreIds(Iterable<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    _scoresLoading = true;
    notifyListeners();
    final linked = await _scoresRepo.getScoresById(scoreIds);
    await _linkScores(linked);
    _scoresLoading = false;
  }

  Future<void> _linkScores(Iterable<Score> scores) async {
    _scoreEntries.addAll(_toEntries(scores));
    notifyListeners();
    await _persistExerciseScores();
  }

  Future<void> importScores() async {
    _scoresLoading = true;
    notifyListeners();
    try {
      final files = await selectScoreFiles();
      if (files.isEmpty) return;

      await _importFiles(files);
    } finally {
      _scoresLoading = false;
      notifyListeners();
    }
  }

  Future<void> scanScores() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _scoresLoading = true;
    notifyListeners();
    try {
      final pdfPaths = await CunningDocumentScanner.getPictures(
        scannerSource: ScannerSource.camera,
        asPdf: true,
      );
      if (pdfPaths == null || pdfPaths.isEmpty) return;

      try {
        await _importFiles(
          pdfPaths.map((p) => XFile(p, mimeType: "application/pdf")),
        );
      } finally {
        await CunningDocumentScanner.cleanCache();
      }
    } finally {
      _scoresLoading = false;
      notifyListeners();
    }
  }

  Future<void> receiveDrop(Iterable<XFile> files) async {
    _scoresLoading = true;
    notifyListeners();
    try {
      await _importFiles(files);
    } finally {
      await DesktopDrop.instance.clearReceivingCache();
      _scoresLoading = false;
      notifyListeners();
    }
  }

  Future<void> _importFiles(Iterable<XFile> files) async {
    final scores = await _scoresRepo.importAll(
      files,
      type: ScoreType.exercise,
      status: _exerciseId == null
          ? ScoreStatus.uncreatedParent
          : ScoreStatus.created,
    );
    _scoreEntries.addAll(_toEntries(scores));
    notifyListeners();
    await _persistExerciseScores();
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
      MetadataFormViewModel.valuesDebounceDuration,
      () => _saveScoreTitle(scoreId),
    );
  }

  Future<void> changeScoreFile(String scoreId) async {
    final file = await selectScoreFile();
    if (file == null) return;
    await _scoresRepo.updateScoreFile(scoreId, file);
    await _reloadScore(scoreId);
  }

  Future<void> _reloadScore(String scoreId) async {
    final scores = await _scoresRepo.getScoresById([scoreId]);
    if (scores.isEmpty) return;
    final score = scores.first;
    var changed = false;
    for (final (i, e) in _scoreEntries.indexed) {
      if (e.score.id != scoreId) continue;
      _scoreEntries[i] = e.withScore(
        _scoreTitleDebounce.containsKey(scoreId)
            ? score.copyWith(title: e.score.title)
            : score,
      );
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
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

  List<ExerciseScoreEntry> _toEntries(Iterable<Score> scores) => scores
      .map((s) => ExerciseScoreEntry(id: _nextEntryId++, score: s))
      .toList();

  Future<bool> create() async {
    if (form.invalid) {
      throw StateError("Only call create when the form is valid!");
    }
    if (_creating) return false;
    _creating = true;
    try {
      _created = !hasNext;
      await _repo.createExercise(
        name: name,
        description: formValue(formDescription),
        instrument: formValue(formInstrument),
        source: formValue(formSource),
        sourceLink: hasSource ? sourceLink ?? "" : "",
        tagIds: tags.map((t) => t.id),
        scoreIds: _scoreEntries.map((e) => e.score.id),
        categoryId: _category?.id,
        difficulty: difficulty,
      );
      if (!hasNext) return true;

      _reset();

      await _loadCreateScores();
      return true;
    } finally {
      _creating = false;
    }
  }

  void _reset() {
    _nextEntryId = 0;
    resetMetadata();
    _category = null;
    _scoreEntries.clear();
    form.reset();
    notifyListeners();
  }

  Future<void> delete() async {
    if (_exerciseId == null) return;
    cancelSave();
    for (final timer in _scoreTitleDebounce.values) {
      timer.cancel();
    }
    _scoreTitleDebounce.clear();
    await _repo.deleteExercise(_exerciseId);
  }

  Future<void> _loadCreateScores() async {
    if (_exerciseId != null) return;
    var scores = await _scoresRepo.getScoresWithUncreatedParent(
      type: ScoreType.exercise,
    );
    if (scores.isEmpty) {
      _hasNext = false;
      return;
    }
    if (_separate) {
      _hasNext = scores.length > 1;
      scores = [scores.first];
    } else {
      _hasNext = false;
    }
    await _linkScores(scores);
  }

  Future<void> _load() async {
    if (_exerciseId == null) return;
    instrumentOptions.reset();
    sourceOptions.reset();
    final exercise = await _repo.getExercise(_exerciseId);
    // TODO properly handle exercise == null
    if (exercise != null) {
      _category = exercise.category;
      form.updateValue({
        formName: exercise.name,
        formDescription: exercise.description,
        formInstrument: exercise.instrument ?? "",
        formSource: exercise.source ?? "",
      }, emitEvent: false);
      loadMetadata(
        tags: exercise.tags,
        source: exercise.source,
        sourceLink: exercise.sourceLink,
        difficulty: exercise.difficulty,
      );
      _scoreEntries = _toEntries(await _repo.getExerciseScores(_exerciseId));
    }
    _loading = false;
    notifyListeners();
    _categorySync.sync();
  }

  final Map<String, Timer> _scoreTitleDebounce = {};

  Future<void> _discardImports() async {
    for (final timer in _scoreTitleDebounce.values) {
      timer.cancel();
    }
    _scoreTitleDebounce.clear();
    _scoreEntries.clear();
    await _scoresRepo.deleteScoresWithUncreatedParent();
  }

  @override
  void dispose() {
    if (_exerciseId == null && !_created) {
      _discardImports();
    } else {
      _saveScoreTitles();
    }
    _categorySync.dispose();
    super.dispose();
  }
}
