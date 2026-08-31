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
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';

class EditRoutineViewModel extends ChangeNotifier {
  static const String formName = "name";
  static const String formDescription = "description";

  static const _valuesDebounceDuration = Duration(milliseconds: 250);

  final PracticeRepository _repo;

  final String? _routineId;

  String? get routineId => _routineId;

  final bool isCreate;

  bool _loading;

  bool get loading => _loading;

  bool _missing = false;

  /// True when the routine that should be edited does not exist.
  bool get missing => _missing;

  final FormGroup form;

  String get name => _formValue(formName);

  List<PracticeRoutineEntry> _entries = [];

  UnmodifiableListView<PracticeRoutineEntry> get entries =>
      UnmodifiableListView(_entries);

  Duration get targetDuration => _entries.fold(
    Duration.zero,
    (sum, e) => sum + (e.targetDuration ?? Duration.zero),
  );

  bool _exercisesLoading = false;

  bool get exercisesLoading => _exercisesLoading;

  StreamSubscription? _valueSub;

  Timer? _valuesDebounce;

  EditRoutineViewModel({required this._repo, String? routineId})
    : _routineId = routineId,
      isCreate = routineId == null,
      _loading = routineId != null,
      form = FormGroup({
        formName: FormControl<String>(validators: [Validators.required]),
        formDescription: FormControl<String>(),
      }) {
    _load().then((_) {
      _valueSub = form.valueChanges.listen((_) {
        if (form.invalid) return;
        _onValuesChanged();
      });
    });
  }

  Future<void> addExercises(Iterable<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return;
    _exercisesLoading = true;
    notifyListeners();
    try {
      final exercises = await _repo.getExercisesById(exerciseIds);
      for (final exerciseId in exerciseIds) {
        final exercise = exercises[exerciseId];
        if (exercise == null) continue;
        _entries.add(
          PracticeRoutineEntry(
            id: _repo.newRoutineEntryId(),
            exercise: exercise,
          ),
        );
      }
    } finally {
      _exercisesLoading = false;
      notifyListeners();
    }
    await _persistEntries();
  }

  Future<void> moveEntry(int from, int to) async {
    if (from == to) return;
    _entries.insert(to, _entries.removeAt(from));
    notifyListeners();
    await _persistEntries();
  }

  Future<void> removeEntry(String entryId) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1) return;
    _entries.removeAt(index);
    _durationDebounce.remove(entryId)?.cancel();
    notifyListeners();
    await _persistEntries();
  }

  final Map<String, Timer> _durationDebounce = {};

  void setTargetDuration(String entryId, Duration? duration) {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1 || _entries[index].targetDuration == duration) return;
    _entries[index] = _entries[index].withTargetDuration(duration);
    notifyListeners();
    _durationDebounce[entryId]?.cancel();
    _durationDebounce[entryId] = Timer(_valuesDebounceDuration, () {
      _durationDebounce.remove(entryId);
      _persistEntries();
    });
  }

  Future<void> create() async {
    if (form.invalid) {
      throw StateError("Only call create when the form is valid!");
    }
    await _repo.createRoutine(
      name: name,
      description: _formValue(formDescription),
      entries: _entries,
    );
  }

  Future<void> delete() async {
    if (_routineId == null) return;
    _cancelDebounces();
    await _repo.deleteRoutine(_routineId);
  }

  Future<void> _persistEntries() async {
    if (_routineId == null) return;
    await _repo.setRoutineEntries(_routineId, _entries);
  }

  Future<void> _load() async {
    if (_routineId == null) return;
    final routine = await _repo.getRoutine(_routineId);
    if (routine == null) {
      _missing = true;
    } else {
      _entries = [...routine.entries];
      form.updateValue({
        formName: routine.name,
        formDescription: routine.description ?? "",
      }, emitEvent: false);
    }
    _loading = false;
    notifyListeners();
  }

  void _onValuesChanged() {
    if (_routineId == null) return;
    _valuesDebounce?.cancel();
    _valuesDebounce = Timer(_valuesDebounceDuration, _saveValues);
  }

  Future<void> _saveValues() async {
    if (_valuesDebounce == null) return;
    _valuesDebounce!.cancel();
    _valuesDebounce = null;
    await _repo.updateRoutine(
      _routineId!,
      name: name,
      description: _formValue(formDescription),
    );
  }

  Future<void> _saveTargetDurations() async {
    if (_durationDebounce.isEmpty) return;
    _cancelDurationDebounces();
    await _persistEntries();
  }

  void _cancelDurationDebounces() {
    for (final timer in _durationDebounce.values) {
      timer.cancel();
    }
    _durationDebounce.clear();
  }

  void _cancelDebounces() {
    _valuesDebounce?.cancel();
    _valuesDebounce = null;
    _cancelDurationDebounces();
  }

  String _formValue(String control) =>
      (form.control(control).value as String? ?? "").trim();

  @override
  void dispose() {
    _saveValues();
    _saveTargetDurations();
    _valueSub?.cancel();
    super.dispose();
  }
}
