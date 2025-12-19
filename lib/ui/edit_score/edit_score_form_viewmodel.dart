import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScoreFormViewModel extends ChangeNotifier {
  final ScoresRepository _repo;
  final EditScoreViewModel _editScoreViewModel;

  Score _score;
  Score get score => _score;

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
    _valueSub = form.valueChanges
        .debounceTime(const Duration(milliseconds: 250))
        .listen((_) {
          if (form.invalid) return;
          _onValuesChanged(form.value);
        });
    _editScoreViewModel.addListener(_onScoreChanged);
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

    notifyListeners();
  }

  Future<void> _onValuesChanged(Map<String, dynamic> values) async {
    await _editScoreViewModel.edit(
      title: values[formTitle],
      composer: values[formComposer] ?? "",
    );
  }

  @override
  void dispose() {
    _editScoreViewModel.removeListener(_onScoreChanged);
    _valueSub?.cancel();
    super.dispose();
  }
}
