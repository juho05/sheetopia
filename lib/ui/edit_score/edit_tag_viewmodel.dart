/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';

class EditTagViewModel {
  static const formName = "name";
  static const formColor = "color";

  final String? _tagId;

  bool get editMode => _tagId != null;

  final ScoresRepository _repo;

  final TagType _type;

  final FormGroup form;

  EditTagViewModel({
    required this._repo,
    required this._type,
    String? initialName,
    Color? initialColor,
    this._tagId,
  }) : form = FormGroup({
         formName: FormControl<String>(
           value: initialName,
           validators: [Validators.required],
         ),
         formColor: FormControl<Color>(
           value: initialColor ?? Colors.indigo,
           validators: [Validators.required],
         ),
       });

  Future<Tag> createTag() async {
    return await _repo.createTag(
      name: form.control(formName).value,
      color: form.control(formColor).value,
      type: _type,
    );
  }

  Future<void> updateTag() async {
    await _repo.updateTag(
      _tagId!,
      name: form.control(formName).value,
      color: form.control(formColor).value,
    );
  }
}
