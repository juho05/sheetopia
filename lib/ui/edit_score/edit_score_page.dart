/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/two_pane_page.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form.dart';
import 'package:sheetopia/ui/edit_score/edit_score_preview.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScorePage extends StatelessWidget {
  final String scoreId;

  const EditScorePage({super.key, required this.scoreId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditScoreViewModel>(
      create: (context) =>
          EditScoreViewModel(repo: context.read(), scoreId: scoreId),
      builder: (context, _) {
        return Consumer<EditScoreViewModel>(
          builder: (context, viewModel, _) {
            return TwoPanePage(
              appBar: AppBar(
                title: viewModel.isImport
                    ? (viewModel.hasNext
                          ? const Text("Import scores")
                          : const Text("Import score"))
                    : const Text("Edit score"),
              ),
              primaryLabel: "Metadata",
              secondaryLabel: "File",
              loading: viewModel.score == null,
              lockSecondarySwipe: true,
              primary: (context) => const EditScoreForm(),
              secondary: (context) => EditScorePreview(score: viewModel.score!),
            );
          },
        );
      },
    );
  }
}
