/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/common/drop_area.dart';
import 'package:sheetopia/ui/common/fab_menu.dart';
import 'package:sheetopia/ui/common/selection/clear_selection_button.dart';
import 'package:sheetopia/ui/common/selection/select_all_button.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/practice/bulk_edit/exercises_bulk_edit_menu.dart';
import 'package:sheetopia/ui/practice/exercises_view.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';
import 'package:sheetopia/ui/practice/import_exercise_scores_choice_dialog.dart';
import 'package:sheetopia/ui/practice/manage_categories_dialog.dart';
import 'package:sheetopia/utils/receive_drop.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  static const double _fabPadding = 88;

  late final ExercisesViewModel _viewModel;

  final SelectionModel _selection = SelectionModel();

  @override
  void initState() {
    super.initState();
    _viewModel = ExercisesViewModel(
      repo: context.read(),
      scoresRepo: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _selection.dispose();
    super.dispose();
  }

  Future<void> _selectAll() async {
    _selection.selectAll(await _viewModel.getFilteredExerciseIds());
  }

  PreferredSizeWidget _buildAppBar(bool selecting) {
    return AppBar(
      centerTitle: false,
      leading: selecting
          ? ClearSelectionButton(onPressed: _selection.clear)
          : null,
      title: Text(selecting ? "${_selection.length} selected" : "Exercises"),
      actions: selecting
          ? [
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) => SelectAllButton(
                  resultCount: _viewModel.resultCount,
                  selectedCount: _selection.length,
                  onSelectAll: _selectAll,
                  onClearSelection: _selection.clear,
                ),
              ),
              ExercisesBulkEditMenu(
                selectedExerciseIds: _selection.ids,
                onDeleted: _selection.clear,
              ),
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _selection,
      builder: (context, _) {
        final selecting = _selection.isNotEmpty;
        return PopScope(
          canPop: !selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _selection.clear();
          },
          child: DropArea(
            onDrop: (List<XFile> files) async {
              bool separate = false;
              if (files.length > 1) {
                final choice = await ImportExerciseScoresChoiceDialog.show(
                  context,
                );
                if (choice == null) {
                  await DesktopDrop.instance.clearReceivingCache();
                  return;
                }
                separate = choice == ImportExerciseScoresChoice.separate;
              }
              if (!context.mounted) {
                await DesktopDrop.instance.clearReceivingCache();
                return;
              }
              context.go("/practice/exercises/create?separate=$separate");
              try {
                final ok = await receiveExercise(context.read(), files);
                if (!context.mounted || !ok) {
                  return;
                }
              } on InvalidFileTypeException catch (e, st) {
                Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
              } catch (e, st) {
                Toast.exception(
                  e,
                  st: st,
                  errorMsg: "Failed to import exercise!",
                );
              }
            },
            child: Scaffold(
              appBar: _buildAppBar(selecting),
              floatingActionButton: FabMenu(
                icon: const Icon(Symbols.edit),
                items: [
                  FabMenuItem(
                    label: "Create exercise",
                    onPressed: () {
                      context.go("/practice/exercises/create");
                    },
                    icon: Symbols.add,
                  ),
                  FabMenuItem(
                    label: "Manage categories",
                    onPressed: () => ManageCategoriesDialog.show(context),
                    icon: Symbols.category,
                  ),
                ],
              ),
              body: SafeArea(
                child: ExercisesView(
                  viewModel: _viewModel,
                  selectionMode: selecting,
                  selected: _selection.idSet,
                  onExerciseSelected: (exercise) =>
                      _selection.select(exercise.id),
                  onExerciseDeselected: (exercise) =>
                      _selection.deselect(exercise.id),
                  onExercisesSelected: _selection.selectAll,
                  onClearSelection: _selection.clear,
                  bottomPadding: _fabPadding,
                  emptyAction: FilledButton.icon(
                    onPressed: () => context.go("/practice/exercises/create"),
                    icon: const Icon(Symbols.add),
                    label: const Text("Create exercise"),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
