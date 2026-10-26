/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/ui/common/next_button.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class NextDoneButton extends StatelessWidget {
  final EditScoreViewModel viewModel;

  const NextDoneButton({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return viewModel.hasNext
        ? NextButton(onPressed: () => viewModel.next())
        : FilledButton(
            onPressed: () => context.pop(),
            child: const Text("Done"),
          );
  }
}
