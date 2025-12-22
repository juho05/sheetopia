import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

class CreateTagViewModel {
  static const formName = "name";
  static const formColor = "color";

  final ScoresRepository _repo;

  final FormGroup form;

  CreateTagViewModel({required ScoresRepository repo, String? initialName})
    : _repo = repo,
      form = FormGroup({
        formName: FormControl<String>(
          value: initialName,
          validators: [Validators.required],
        ),
        formColor: FormControl<Color>(
          value: Colors.indigo,
          validators: [Validators.required],
        ),
      });

  Future<Tag> createTag() async {
    return await _repo.createTag(
      name: form.control(formName).value,
      color: form.control(formColor).value,
    );
  }
}
