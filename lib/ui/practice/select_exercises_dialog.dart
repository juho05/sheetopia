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
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/common/selection/select_all_button.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/exercises_view.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';
import 'package:sheetopia/ui/practice/new_exercise_dialog.dart';
import 'package:sheetopia/ui/setlists/add_scores_dialog.dart';

class SelectExercisesDialog extends StatefulWidget {
  const SelectExercisesDialog._();

  static Future<List<String>?> show(BuildContext context) {
    return showSheetopiaDialog<List<String>>(
      context: context,
      builder: (context) => const SelectExercisesDialog._(),
    );
  }

  @override
  State<SelectExercisesDialog> createState() => _SelectExercisesDialogState();
}

class _SelectExercisesDialogState extends State<SelectExercisesDialog> {
  final SelectionModel _selected = SelectionModel();

  late final ExercisesViewModel _viewModel;

  late final PracticeRepository _repo;

  late final ScoresRepository _scoresRepo;

  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read();
    _scoresRepo = context.read();
    _viewModel = ExercisesViewModel(repo: _repo, scoresRepo: _scoresRepo);
  }

  Future<void> _createFromScores() async {
    if (_creating) return;
    _creating = true;
    try {
      final scoreIds = await AddScoresDialog.show(context);
      if (scoreIds == null || scoreIds.isEmpty || !mounted) return;
      final scores = await _scoresRepo.getScoresById(scoreIds.take(1));
      if (!mounted) return;
      final details = await NewExerciseDialog.show(
        context,
        initialName: scores.firstOrNull?.title ?? "",
      );
      if (details == null || !mounted) return;
      final exerciseId = await _repo.createExercise(
        name: details.name,
        description: "",
        instrument: "",
        source: "",
        sourceLink: "",
        tagIds: const [],
        scoreIds: scoreIds,
        categoryId: details.category?.id,
      );
      if (!mounted) return;
      Navigator.pop(context, [..._selected.ids, exerciseId]);
    } finally {
      _creating = false;
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _selected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _selected,
      builder: (context, _) => _buildDialog(context, theme),
    );
  }

  Widget _buildDialog(BuildContext context, ThemeData theme) {
    return SheetopiaDialog(
      maxWidth: 900,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    _selected.isEmpty
                        ? "Add exercises"
                        : "${_selected.length} selected",
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) => SelectAllButton(
                    resultCount: _viewModel.resultCount,
                    selectedCount: _selected.length,
                    onSelectAll: () async => _selected.selectAll(
                      await _viewModel.getFilteredExerciseIds(),
                    ),
                    onClearSelection: _selected.clear,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ExercisesView(
                viewModel: _viewModel,
                selected: _selected.idSet,
                selectionMode: true,
                onExerciseSelected: (exercise) => _selected.select(exercise.id),
                onExerciseDeselected: (exercise) =>
                    _selected.deselect(exercise.id),
                onExercisesSelected: _selected.selectAll,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final createButton = OutlinedButton.icon(
                  onPressed: _createFromScores,
                  icon: const Icon(Symbols.add),
                  label: const Text(
                    "Create from score",
                    overflow: TextOverflow.ellipsis,
                  ),
                );
                final actions = Row(
                  spacing: 8,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.pop(context, [..._selected.ids]),
                      child: const Text("Add"),
                    ),
                  ],
                );
                if (constraints.maxWidth < 400) {
                  return Column(
                    spacing: 8,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: createButton,
                      ),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  );
                }
                return Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: createButton),
                    actions,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
