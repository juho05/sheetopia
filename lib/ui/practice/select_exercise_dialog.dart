/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/exercises_view.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';

class SelectExerciseDialog extends StatefulWidget {
  const SelectExerciseDialog._();

  static Future<Exercise?> show(BuildContext context) {
    return showSheetopiaDialog<Exercise>(
      context: context,
      builder: (context) => const SelectExerciseDialog._(),
    );
  }

  @override
  State<SelectExerciseDialog> createState() => _SelectExerciseDialogState();
}

class _SelectExerciseDialogState extends State<SelectExerciseDialog> {
  late final ExercisesViewModel _viewModel;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 900,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          spacing: 8,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select exercise",
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ExercisesView(
                viewModel: _viewModel,
                onExercisePicked: (exercise) =>
                    Navigator.pop(context, exercise),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
