/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/bulk_edit/bulk_edit_metadata_dialog.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/practice/bulk_edit/exercises_bulk_edit_menu_viewmodel.dart';
import 'package:sheetopia/ui/practice/exercise_field.dart';
import 'package:sheetopia/ui/practice/select_routine_dialog.dart';

class ExercisesBulkEditMenu extends StatefulWidget {
  final List<String> selectedExerciseIds;
  final void Function()? onDeleted;

  const ExercisesBulkEditMenu({
    super.key,
    required this.selectedExerciseIds,
    this.onDeleted,
  });

  @override
  State<ExercisesBulkEditMenu> createState() => _ExercisesBulkEditMenuState();
}

class _ExercisesBulkEditMenuState extends State<ExercisesBulkEditMenu> {
  late final ExercisesBulkEditMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ExercisesBulkEditMenuViewModel(
      repo: context.read(),
      selectedExercises: widget.selectedExerciseIds,
    );
  }

  @override
  void didUpdateWidget(covariant ExercisesBulkEditMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _viewModel.updateSelectedExercises(widget.selectedExerciseIds);
  }

  Future<void> _delete() async {
    final count = _viewModel.selectedCount;
    final exercises = count == 1 ? "exercise" : "exercises";
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete $count $exercises?",
      message:
          "They will be deleted on all your devices and removed from "
          "every routine that uses them.",
    );
    if (!confirmed) return;
    final deleted = await _viewModel.delete();
    widget.onDeleted?.call();
    Toast.show("Deleted $deleted ${deleted == 1 ? "exercise" : "exercises"}");
  }

  Future<void> _editMetadata() async {
    final count = _viewModel.selectedCount;
    final edit = await BulkEditMetadataDialog.show(
      context,
      title: "Edit metadata of $count ${count == 1 ? "exercise" : "exercises"}",
      fields: [
        const BulkMetadataField(ExerciseField.category, BulkInputKind.category),
        BulkMetadataField(
          ExerciseField.instrument,
          BulkInputKind.text,
          getOptions: (filter, _) => _viewModel.getInstruments(filter: filter),
        ),
        const BulkMetadataField(
          ExerciseField.difficulty,
          BulkInputKind.difficulty,
        ),
        BulkMetadataField(
          ExerciseField.source,
          BulkInputKind.source,
          getOptions: (filter, _) => _viewModel.getSources(filter: filter),
        ),
        const BulkMetadataField(
          ExerciseField.tags,
          BulkInputKind.tags,
          tagType: TagType.exercise,
        ),
      ],
    );
    if (edit == null) return;
    switch (edit) {
      case BulkCategoryEdit(:final category):
        await _viewModel.editCategory(category?.id);
      case BulkTextEdit(:final value):
        await _viewModel.editInstrument(value);
      case BulkSourceEdit(:final source, :final sourceLink):
        await _viewModel.editSource(source, sourceLink);
      case BulkTagsEdit(:final addIds, :final removeIds):
        await _viewModel.editTags(addIds.toSet(), removeIds.toSet());
      case BulkDifficultyEdit(:final difficulty):
        await _viewModel.editDifficulty(difficulty);
      case BulkValuesEdit():
        return;
    }
    Toast.show(
      "Successfully updated ${edit.field.label.toLowerCase()} of selected exercises",
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Edit metadata",
          icon: Symbols.edit_note,
          onSelected: _editMetadata,
        ),
        ContextMenuOption(
          title: "Add to routine",
          icon: Symbols.playlist_add,
          onSelected: () async {
            final routine = await SelectRoutineDialog.show(
              context,
              title: "Add to routine",
            );
            if (routine == null) return;
            final count = await _viewModel.addToRoutine(routine.id);
            Toast.show(
              "Added $count ${count == 1 ? "exercise" : "exercises"} "
              "to \"${routine.name}\"",
            );
          },
        ),
        ContextMenuOption(
          title: "Delete",
          icon: Symbols.delete,
          onSelected: _delete,
        ),
      ],
    );
  }
}
