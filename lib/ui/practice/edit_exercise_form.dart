/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/metadata_form.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';
import 'package:sheetopia/ui/practice/edit_exercise_viewmodel.dart';
import 'package:sheetopia/ui/practice/exercise_field.dart';

class EditExerciseForm extends StatelessWidget {
  const EditExerciseForm({super.key});

  Widget _fieldValueWidget(
    EditExerciseViewModel viewModel,
    ExerciseField field,
    FocusNode focusNode,
  ) {
    switch (field) {
      case ExerciseField.category:
        return CategorySelector(
          category: viewModel.category,
          emptyLabel: "No category",
          label: null,
          inline: true,
          allowCreate: true,
          onChanged: viewModel.setCategory,
        );
      case ExerciseField.instrument:
        return MetadataAutoCompleteField(
          form: viewModel.form,
          formControlName: EditExerciseViewModel.formInstrument,
          focusNode: focusNode,
          getOptions: viewModel.instrumentOptions.get,
        );
      case ExerciseField.tags:
        return MetadataTagsValue(viewModel: viewModel, type: TagType.exercise);
      case ExerciseField.difficulty:
        return MetadataDifficultyValue(viewModel: viewModel);
      case ExerciseField.source:
        return MetadataSourceValue(
          viewModel: viewModel,
          focusNode: focusNode,
          getOptions: viewModel.sourceOptions.get,
        );
      case ExerciseField.description:
        return MetadataTextValue(
          formControlName: EditExerciseViewModel.formDescription,
          focusNode: focusNode,
          hintText: "No description",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditExerciseViewModel>(
      builder: (context, viewModel, _) {
        return MetadataForm<ExerciseField>(
          viewModel: viewModel,
          titleControlName: EditExerciseViewModel.formName,
          permanentFields: const [
            ExerciseField.category,
            ExerciseField.instrument,
            ExerciseField.tags,
            ExerciseField.description,
          ],
          stackedFields: const {ExerciseField.description},
          buildFieldWidget: (field, focusNode) =>
              _fieldValueWidget(viewModel, field, focusNode),
          onAdd: (field) async => viewModel.showField(field),
          removeMessage: (field) =>
              "Remove the ${field.label.toLowerCase()} from this exercise?",
          action: viewModel.isCreate
              ? _CreateButton(viewModel: viewModel)
              : null,
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  final EditExerciseViewModel viewModel;

  const _CreateButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, _) => FilledButton(
        onPressed: form.valid
            ? () async {
                bool hasNext = viewModel.hasNext;
                if (!await viewModel.create()) return;
                if (hasNext || !context.mounted) return;
                context.pop();
              }
            : null,
        child: viewModel.hasNext ? const Text("Next") : const Text("Create"),
      ),
    );
  }
}
