/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/fab_menu.dart';
import 'package:sheetopia/ui/common/selection/clear_selection_button.dart';
import 'package:sheetopia/ui/common/selection/select_all_button.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/practice/bulk_edit/exercises_bulk_edit_menu.dart';
import 'package:sheetopia/ui/practice/exercises_view.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';
import 'package:sheetopia/ui/practice/manage_categories_dialog.dart';

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
          child: Scaffold(
            appBar: _buildAppBar(selecting),
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
          ),
        );
      },
    );
  }
}
