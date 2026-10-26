/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'dart:async';
import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';
import 'package:sheetopia/ui/common/source_value.dart';
import 'package:sheetopia/ui/common/visible_fields.dart';

class CachedOptions {
  final Future<List<String>> Function() _load;
  List<String>? _values;

  CachedOptions(this._load);

  Future<Iterable<String>> get(String filter) async {
    final values = _values ??= await _load();
    filter = filter.toLowerCase();
    return values.where((v) => v.toLowerCase().contains(filter)).take(10);
  }

  void reset() => _values = null;
}

mixin MetadataFormViewModel<T extends MetadataField> on ChangeNotifier {
  static const String formSource = "source";

  FormGroup get form;

  List<T> get optionalFields;

  bool isFilled(T field);

  Future<void> clearField(T field);

  bool get canPersist;

  Future<void> persistValues();

  Future<void> persistSource(String source, String sourceLink);

  Future<void> persistDifficulty(Difficulty? difficulty);

  Future<void> persistAddTags(Iterable<Tag> tags);

  Future<void> persistRemoveTag(Tag tag);

  static int _byName(Tag a, Tag b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());

  SplayTreeSet<Tag> _tags = SplayTreeSet(_byName);

  Iterable<Tag> get tags => _tags;

  final _source = SourceState();

  String? get source => _source.name;

  String? get sourceLink => _source.link;

  bool get hasSource => formValue(formSource).isNotEmpty;

  Difficulty? _difficulty;

  Difficulty? get difficulty => _difficulty;

  late final VisibleFields<T> _fields = VisibleFields(
    optionalFields,
    isFilled: isFilled,
  );

  bool isVisible(T field) => _fields.isVisible(field);

  Iterable<T> get hiddenFields => _fields.hidden;

  String formValue(String control) =>
      (form.control(control).value as String? ?? "").trim();

  void loadMetadata({
    required Iterable<Tag> tags,
    required String? source,
    required String? sourceLink,
    required Difficulty? difficulty,
  }) {
    _tags = SplayTreeSet.of(tags, _byName);
    _source.load(source, sourceLink);
    _difficulty = difficulty;
    _fields.clear();
    _fields.showFilled();
  }

  /// unlike [loadMetadata] this keeps the visible fields and an unsaved
  /// source link
  void syncMetadata({
    required Iterable<Tag> tags,
    required String? source,
    required String? sourceLink,
    required Difficulty? difficulty,
  }) {
    _tags = SplayTreeSet.of(tags, _byName);
    final control = form.control(formSource);
    if (formValue(formSource) == (_source.name ?? "")) {
      control.updateValue(source ?? "", updateParent: false);
      form.updateValueAndValidity(emitEvent: false);
    }
    _source.sync(source, sourceLink);
    _difficulty = difficulty;
    _fields.showFilled();
  }

  void showField(T field) {
    if (!_fields.show(field)) return;
    notifyListeners();
  }

  Future<void> removeField(T field) async {
    _fields.remove(field);
    await clearField(field);
    notifyListeners();
  }

  Future<void> addTags(Iterable<Tag> tags) async {
    _tags.addAll(tags);
    notifyListeners();
    if (!canPersist) return;
    await persistAddTags(tags);
  }

  Future<void> removeTag(Tag tag) async {
    _tags.remove(tag);
    notifyListeners();
    if (!canPersist) return;
    await persistRemoveTag(tag);
  }

  void setTags(Iterable<Tag> tags) {
    _tags = SplayTreeSet.of(tags, _byName);
    notifyListeners();
  }

  Future<void> setSource(String source, String sourceLink) async {
    _source.set(source, sourceLink);
    if (formValue(formSource) != source) {
      form.control(formSource).value = source;
    }
    notifyListeners();
    if (!canPersist) return;
    await persistSource(source, _source.savedLink);
  }

  Future<void> setSourceLink(String link) =>
      setSource(formValue(formSource), link);

  Future<void> setDifficulty(Difficulty? difficulty) async {
    if (_difficulty == difficulty) return;
    _difficulty = difficulty;
    notifyListeners();
    if (!canPersist) return;
    await persistDifficulty(difficulty);
  }

  void resetMetadata() {
    _tags.clear();
    _source.clear();
    _difficulty = null;
    _fields.clear();
  }

  StreamSubscription? _valueSub;
  Timer? _valuesDebounce;
  static const valuesDebounceDuration = Duration(milliseconds: 250);

  void listenToValues() {
    _valueSub = form.valueChanges.listen((_) {
      if (form.invalid || !canPersist) return;
      _valuesDebounce?.cancel();
      _valuesDebounce = Timer(valuesDebounceDuration, saveValues);
    });
  }

  void cancelSave() {
    _valuesDebounce?.cancel();
    _valuesDebounce = null;
  }

  Future<void> saveValues() async {
    if (_valuesDebounce == null) return;
    cancelSave();
    if (!canPersist) return;
    final source = formValue(formSource);
    final sourceChanged = _source.updateName(source);
    if (sourceChanged && !_disposed) notifyListeners();
    await persistValues();
    if (!sourceChanged) return;
    await persistSource(source, _source.savedLink);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    saveValues();
    _valueSub?.cancel();
    super.dispose();
  }
}
