/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/metadata_filter_dialog.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/text_filter_field.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';
import 'package:sheetopia/ui/practice/exercise_field.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';

class ExercisesFilterDialog extends StatelessWidget {
  final ExercisesViewModel _viewModel;

  const ExercisesFilterDialog._({required this._viewModel});

  static Future<void> show(
    BuildContext context, {
    required ExercisesViewModel viewModel,
  }) async {
    return await showSheetopiaDialog(
      context: context,
      builder: (context) => ExercisesFilterDialog._(viewModel: viewModel),
    );
  }

  bool _isFiltered(ExerciseField field) => switch (field) {
    ExerciseField.difficulty => _viewModel.filterDifficulties.isNotEmpty,
    ExerciseField.source => _viewModel.filterSource.isNotEmpty,
    _ => false,
  };

  void _clearField(ExerciseField field) {
    if (field == ExerciseField.source) _viewModel.filterSource = "";
    if (field == ExerciseField.difficulty) {
      _viewModel.clearFilterDifficulties();
    }
  }

  Widget _fieldValueWidget(ExerciseField field, bool autofocus) {
    return switch (field) {
      ExerciseField.category => CategorySelector(
        category: _viewModel.filterCategory,
        emptyLabel: "All categories",
        label: null,
        inline: true,
        onChanged: (category) => _viewModel.filterCategory = category,
      ),
      ExerciseField.instrument => TextFilterField(
        value: _viewModel.filterInstrument,
        getOptions: (filter) => _viewModel.getInstruments(filter: filter),
        onChanged: (value) => _viewModel.filterInstrument = value,
      ),
      ExerciseField.tags => FilterTagsValue(
        viewModel: _viewModel,
        type: TagType.exercise,
      ),
      ExerciseField.source => TextFilterField(
        value: _viewModel.filterSource,
        autofocus: autofocus,
        getOptions: (filter) => _viewModel.getSources(filter: filter),
        onChanged: (value) => _viewModel.filterSource = value,
      ),
      ExerciseField.difficulty => FilterDifficultyValue(viewModel: _viewModel),
      ExerciseField.description => const SizedBox(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MetadataFilterDialog<ExerciseField>(
      viewModel: _viewModel,
      permanentFields: const [
        ExerciseField.category,
        ExerciseField.instrument,
        ExerciseField.tags,
      ],
      optionalFields: ExerciseField.exerciseFilterOptional,
      isFiltered: _isFiltered,
      buildValue: _fieldValueWidget,
      trailing: (field) => [
        if (field == ExerciseField.tags) FilterTagMatch(viewModel: _viewModel),
      ],
      clearField: _clearField,
    );
  }
}
