/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/bulk_edit/bulk_edit_tags_dialog.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/source_input_dialog.dart';
import 'package:sheetopia/ui/practice/bulk_edit/exercises_bulk_edit_menu_viewmodel.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';
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

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Edit category",
          icon: Symbols.category,
          onSelected: () async {
            final choice = await SelectCategoryDialog.show(
              context,
              selected: null,
              emptyLabel: "No category",
              allowCreate: true,
            );
            if (choice == null) return;
            await _viewModel.editCategory(choice.category?.id);
            Toast.show("Successfully updated category of selected exercises");
          },
        ),
        ContextMenuOption(
          title: "Edit instrument",
          icon: Symbols.piano,
          onSelected: () async {
            final instrument = await AutoCompleteInputDialog.show(
              context,
              title: "Bulk edit instrument",
              inputLabel: "Instrument",
              submitBtnText: "Update",
              enableClear: true,
              getOptions: (filter) => _viewModel.getInstruments(filter: filter),
            );
            if (instrument == null) return;
            await _viewModel.editInstrument(instrument);
            Toast.show("Successfully updated instrument of selected exercises");
          },
        ),
        ContextMenuOption(
          title: "Edit source",
          icon: Symbols.link,
          onSelected: () async {
            final result = await SourceInputDialog.show(
              context,
              title: "Bulk edit source",
              submitBtnText: "Update",
              enableClear: true,
              getOptions: (filter) => _viewModel.getSources(filter: filter),
            );
            if (result == null) return;
            await _viewModel.editSource(result.source, result.sourceLink);
            Toast.show("Successfully updated source of selected exercises");
          },
        ),
        ContextMenuOption(
          title: "Edit tags",
          icon: Symbols.label,
          onSelected: () async {
            final result = await BulkEditTagsDialog.show(
              context,
              type: TagType.exercise,
            );
            if (result == null) return;
            await _viewModel.editTags(
              result.addIds.toSet(),
              result.removeIds.toSet(),
            );
            Toast.show("Successfully updated tags of selected exercises");
          },
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
