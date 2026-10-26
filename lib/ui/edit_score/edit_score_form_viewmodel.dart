/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/metadata_form_viewmodel.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScoreFormViewModel extends ChangeNotifier
    with MetadataFormViewModel<ScoreField> {
  final ScoresRepository _repo;
  final EditScoreViewModel _editScoreViewModel;

  Score _score;

  Score get score => _score;

  SplayTreeSet<String> _instruments = SplayTreeSet();

  Iterable<String> get instruments => _instruments;

  SplayTreeSet<String> _genres = SplayTreeSet();

  Iterable<String> get genres => _genres;

  @override
  List<ScoreField> get optionalFields => ScoreField.formOptional;

  @override
  final FormGroup form;

  static const String formTitle = "title";
  static const String formComposer = "composer";
  static const String formArranger = "arranger";
  static const String formPartOf = "partOf";
  static const String formSource = MetadataFormViewModel.formSource;
  static const String formNotes = "notes";

  late final composerOptions = CachedOptions(_repo.getComposers);
  late final arrangerOptions = CachedOptions(_repo.getArrangers);
  late final partOfOptions = CachedOptions(_repo.getPartOfs);
  late final sourceOptions = CachedOptions(_repo.getSources);

  EditScoreFormViewModel({
    required EditScoreViewModel editScoreViewModel,
    required ScoresRepository scoresRepo,
  }) : _editScoreViewModel = editScoreViewModel,
       _repo = scoresRepo,
       _score = editScoreViewModel.score!,
       form = FormGroup({
         formTitle: FormControl<String>(
           value: editScoreViewModel.score!.title,
           validators: [Validators.required],
         ),
         formComposer: FormControl<String>(
           value: editScoreViewModel.score!.composer,
         ),
         formArranger: FormControl<String>(
           value: editScoreViewModel.score!.arranger,
         ),
         formPartOf: FormControl<String>(
           value: editScoreViewModel.score!.partOf,
         ),
         formSource: FormControl<String>(
           value: editScoreViewModel.score!.source,
         ),
         formNotes: FormControl<String>(value: editScoreViewModel.score!.notes),
       }) {
    _loadScore().then((value) {
      listenToValues();
      _editScoreViewModel.addListener(_onScoreChanged);
    });
  }

  Future<void> addInstrument(String instrument) async {
    if (!_instruments.add(instrument)) return;
    notifyListeners();
    await _repo.addScoreInstruments(score.id, [instrument]);
  }

  Future<void> removeInstrument(String instrument) async {
    if (!_instruments.remove(instrument)) return;
    notifyListeners();
    await _repo.removeScoreInstruments(score.id, [instrument]);
  }

  Future<void> addGenre(String genre) async {
    if (!_genres.add(genre)) return;
    notifyListeners();
    await _repo.addScoreGenre(score.id, [genre]);
  }

  Future<void> removeGenre(String genre) async {
    if (!_genres.remove(genre)) return;
    notifyListeners();
    await _repo.removeScoreGenres(score.id, [genre]);
  }

  Future<void> _clearGenres() async {
    if (_genres.isEmpty) return;
    final genres = List.of(_genres);
    _genres.clear();
    notifyListeners();
    await _repo.removeScoreGenres(score.id, genres);
  }

  @override
  Future<void> clearField(ScoreField field) async {
    switch (field) {
      case ScoreField.arranger:
        form.control(formArranger).value = "";
      case ScoreField.partOf:
        form.control(formPartOf).value = "";
      case ScoreField.source:
        await setSource("", "");
      case ScoreField.difficulty:
        await setDifficulty(null);
      case ScoreField.genres:
        await _clearGenres();
      case ScoreField.notes:
        form.control(formNotes).value = "";
      case ScoreField.composer || ScoreField.instruments || ScoreField.tags:
        break;
    }
  }

  @override
  bool isFilled(ScoreField field) => switch (field) {
    ScoreField.arranger => formValue(formArranger).isNotEmpty,
    ScoreField.partOf => formValue(formPartOf).isNotEmpty,
    ScoreField.source => hasSource,
    ScoreField.difficulty => difficulty != null,
    ScoreField.genres => _genres.isNotEmpty,
    ScoreField.notes => formValue(formNotes).isNotEmpty,
    _ => false,
  };

  @override
  bool get canPersist => !_editScoreViewModel.deleted;

  @override
  Future<void> persistValues() => _repo.updateScore(
    _score.id,
    title: formValue(formTitle),
    composer: formValue(formComposer),
    arranger: formValue(formArranger),
    partOf: formValue(formPartOf),
    notes: formValue(formNotes),
  );

  @override
  Future<void> persistSource(String source, String sourceLink) =>
      _repo.updateScoreSource(score.id, source: source, sourceLink: sourceLink);

  @override
  Future<void> persistDifficulty(Difficulty? difficulty) =>
      _repo.updateScoreDifficulty(score.id, difficulty);

  @override
  Future<void> persistAddTags(Iterable<Tag> tags) =>
      _repo.addScoreTags(score.id, tags.map((t) => t.id));

  @override
  Future<void> persistRemoveTag(Tag tag) =>
      _repo.removeScoreTag(score.id, tag.id);

  Future<Iterable<String>> getInstruments({String filter = ""}) async {
    return await _repo.getInstruments(
      filter: filter,
      size: 10,
      exclude: instruments,
    );
  }

  Future<Iterable<String>> getGenres({String filter = ""}) async {
    return await _repo.getGenres(filter: filter, size: 10, exclude: genres);
  }

  Future<void> reloadScore() async {
    await saveValues();
    await _loadScore();
  }

  Future<void> _onScoreChanged() async {
    if (_editScoreViewModel.score == null) return;
    if (_editScoreViewModel.score!.id == _score.id) {
      _score = _editScoreViewModel.score!;
      // tags need to be updated because they might have been edited outside of
      // this view model, e.g. in the edit tags dialog
      syncMetadata(
        tags: _score.tags,
        source: _score.source,
        sourceLink: _score.sourceLink,
        difficulty: _score.difficulty,
      );
      notifyListeners();
      return;
    }

    await reloadScore();
  }

  Future<void> _loadScore() async {
    composerOptions.reset();
    arrangerOptions.reset();
    partOfOptions.reset();
    sourceOptions.reset();
    _score = _editScoreViewModel.score!;
    form.updateValue({
      formTitle: _score.title,
      formComposer: _score.composer ?? "",
      formArranger: _score.arranger ?? "",
      formPartOf: _score.partOf ?? "",
      formSource: _score.source ?? "",
      formNotes: _score.notes ?? "",
    });
    _instruments = SplayTreeSet.of(score.instruments);
    _genres = SplayTreeSet.of(score.genres);
    loadMetadata(
      tags: _score.tags,
      source: _score.source,
      sourceLink: _score.sourceLink,
      difficulty: _score.difficulty,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _editScoreViewModel.removeListener(_onScoreChanged);
    super.dispose();
  }
}
