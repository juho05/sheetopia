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
import 'package:sheetopia/data/repositories/scores/tag.dart';

class EditExerciseViewModel extends ChangeNotifier {
  final PracticeRepository _repo;

  final String? _exerciseId;

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

  EditExerciseViewModel({required this._repo, required this._exerciseId})
    : isCreate = _exerciseId == null,
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
    await _repo.createExercise(
      name: name,
      description: _formValue(formDescription),
      instrument: _formValue(formInstrument),
      source: _source ?? "",
      sourceLink: _sourceLink ?? "",
      tagIds: _tags.map((t) => t.id),
      categoryId: _category?.id,
    );
  }

  Future<void> delete() async {
    if (_exerciseId == null) return;
    _valuesDebounce?.cancel();
    _valuesDebounce = null;
    await _repo.deleteExercise(_exerciseId);
  }

  Future<void> reloadExercise() async {
    if (_exerciseId == null) return;
    await _saveValues();
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
    }
    _loading = false;
    notifyListeners();
  }

  Timer? _valuesDebounce;
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

  @override
  void dispose() {
    // pending edits would otherwise be lost when leaving the page
    _saveValues();
    _valueSub?.cancel();
    super.dispose();
  }
}
