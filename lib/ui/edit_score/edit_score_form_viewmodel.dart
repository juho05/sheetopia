import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScoreFormViewModel extends ChangeNotifier {
  final EditScoreViewModel _editScoreViewModel;

  Score _score;
  Score get score => _score;

  final FormGroup form;

  static const String formTitle = "title";

  StreamSubscription? _valueSub;

  EditScoreFormViewModel({required EditScoreViewModel editScoreViewModel})
    : _editScoreViewModel = editScoreViewModel,
      _score = editScoreViewModel.score!,
      form = FormGroup({
        formTitle: FormControl<String>(
          value: editScoreViewModel.score!.title,
          validators: [Validators.required],
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

  Future<void> _onScoreChanged() async {
    if (_editScoreViewModel.score!.id == _score.id) {
      _score = _editScoreViewModel.score!;
      notifyListeners();
      return;
    }

    await _onValuesChanged(form.value);

    _score = _editScoreViewModel.score!;
    form.updateValue({formTitle: _score.title});

    notifyListeners();
  }

  Future<void> _onValuesChanged(Map<String, dynamic> values) async {
    await _editScoreViewModel.edit(title: values[formTitle]);
  }

  @override
  void dispose() {
    _editScoreViewModel.removeListener(_onScoreChanged);
    _valueSub?.cancel();
    super.dispose();
  }
}
