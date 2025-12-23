import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScoreFormViewModel extends ChangeNotifier {
  final ScoresRepository _repo;
  final EditScoreViewModel _editScoreViewModel;

  Score _score;
  Score get score => _score;

  SplayTreeSet<Tag> _tags = SplayTreeSet((a, b) => a.name.compareTo(b.name));
  Iterable<Tag> get tags => _tags;

  SplayTreeSet<String> _instruments = SplayTreeSet();
  Iterable<String> get instruments => _instruments;

  SplayTreeSet<String> _genres = SplayTreeSet();
  Iterable<String> get genres => _genres;

  final FormGroup form;

  static const String formTitle = "title";
  static const String formComposer = "composer";

  StreamSubscription? _valueSub;

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
       }) {
    _instruments = SplayTreeSet.of(score.instruments);
    _genres = SplayTreeSet.of(score.genres);
    _tags = SplayTreeSet.of(score.tags, (a, b) => a.name.compareTo(b.name));
    _valueSub = form.valueChanges.listen((_) {
      if (form.invalid) return;
      _onValuesChanged(form.value);
    });
    _editScoreViewModel.addListener(_onScoreChanged);
  }

  Future<void> addInstrument(String instrument) async {
    if (!_instruments.add(instrument)) return;
    notifyListeners();
    await _repo.addScoreInstruments(score.id, [instrument]);
  }

  Future<void> removeInstrument(String instrument) async {
    if (!_instruments.remove(instrument)) return;
    notifyListeners();
    await _repo.removeScoreInstrument(score.id, instrument);
  }

  Future<void> addGenre(String genre) async {
    if (!_genres.add(genre)) return;
    notifyListeners();
    await _repo.addScoreGenre(score.id, [genre]);
  }

  Future<void> removeGenre(String genre) async {
    if (!_genres.remove(genre)) return;
    notifyListeners();
    await _repo.removeScoreGenre(score.id, genre);
  }

  Future<void> addTags(Iterable<Tag> tags) async {
    _tags.addAll(tags);
    notifyListeners();
    await _repo.addScoreTags(score.id, tags.map((t) => t.id));
  }

  Future<void> removeTagId(String tagId) async {
    _tags.removeWhere((t) => t.id == tagId);
    notifyListeners();
    await _repo.removeScoreTag(score.id, tagId);
  }

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

  List<String>? _composers;
  Future<Iterable<String>> getComposers({String filter = ""}) async {
    _composers ??= await _repo.getComposers();
    return _composers!.where((element) => element.contains(filter)).take(10);
  }

  Future<void> _onScoreChanged() async {
    if (_editScoreViewModel.score!.id == _score.id) {
      _score = _editScoreViewModel.score!;
      notifyListeners();
      return;
    }

    await _onValuesChanged(form.value);

    _composers = null;
    _score = _editScoreViewModel.score!;
    form.updateValue({
      formTitle: _score.title,
      formComposer: _score.composer ?? "",
    });
    _instruments = SplayTreeSet.of(score.instruments);
    _genres = SplayTreeSet.of(score.genres);
    _tags = SplayTreeSet.of(score.tags, (a, b) => a.name.compareTo(b.name));

    notifyListeners();
  }

  Timer? _valuesDebounce;
  static const _valuesDebounceDuration = Duration(milliseconds: 250);
  Future<void> _onValuesChanged(Map<String, dynamic> values) async {
    _valuesDebounce?.cancel();
    _valuesDebounce = Timer(
      _valuesDebounceDuration,
      () => _repo.updateScore(
        _score.id,
        title: values[formTitle],
        composer: values[formComposer] ?? "",
      ),
    );
  }

  @override
  void dispose() {
    _valuesDebounce?.cancel();
    _editScoreViewModel.removeListener(_onScoreChanged);
    _valueSub?.cancel();
    super.dispose();
  }
}
