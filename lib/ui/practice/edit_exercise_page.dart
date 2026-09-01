/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/two_pane_page.dart';
import 'package:sheetopia/ui/practice/edit_exercise_form.dart';
import 'package:sheetopia/ui/practice/edit_exercise_scores.dart';
import 'package:sheetopia/ui/practice/edit_exercise_viewmodel.dart';

class EditExercisePage extends StatelessWidget {
  final String? exerciseId;

  const EditExercisePage({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditExerciseViewModel>(
      create: (context) => EditExerciseViewModel(
        repo: context.read(),
        scoresRepo: context.read(),
        exerciseId: exerciseId,
      ),
      builder: (context, _) {
        return Consumer<EditExerciseViewModel>(
          builder: (context, viewModel, _) {
            final exerciseId = viewModel.exerciseId;
            return TwoPanePage(
              appBar: AppBar(
                title: viewModel.isCreate
                    ? (const Text("Create exercise"))
                    : const Text("Edit exercise"),
                actions: [
                  if (exerciseId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.go("/practice/exercises/$exerciseId/play"),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Play"),
                      ),
                    ),
                ],
              ),
              primaryLabel: "Metadata",
              secondaryLabel: "Scores",
              loading: viewModel.loading,
              lockSecondarySwipe: false,
              primary: (context) => const EditExerciseForm(),
              secondary: (context) => const EditExerciseScores(),
            );
          },
        );
      },
    );
  }
}
