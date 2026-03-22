/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/edit_score/edit_score_desktop.dart';
import 'package:sheetopia/ui/edit_score/edit_score_mobile.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/nextdonedelete_button.dart';

class EditScorePage extends StatelessWidget {
  final String scoreId;

  const EditScorePage({super.key, required this.scoreId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditScoreViewModel>(
      create: (context) =>
          EditScoreViewModel(repo: context.read(), scoreId: scoreId),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 900;
            return Consumer<EditScoreViewModel>(
              child: SafeArea(
                child: mobile
                    ? const EditScoreMobile()
                    : const EditScoreDesktop(),
              ),
              builder: (context, viewModel, child) {
                return Scaffold(
                  appBar: AppBar(
                    title: viewModel.isImport
                        ? (viewModel.hasNext
                              ? const Text("Import scores")
                              : const Text("Import score"))
                        : const Text("Edit score"),
                    actions: [
                      if (mobile)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: NextDoneDeleteButton(viewModel: viewModel),
                        ),
                    ],
                  ),
                  body: child,
                );
              },
            );
          },
        );
      },
    );
  }
}
