/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';

enum ImportExerciseScoresChoice { separate, single }

class ImportExerciseScoresChoiceDialog {
  static Future<ImportExerciseScoresChoice?> show(
    BuildContext context, {
    String title = "Import as",
  }) async {
    return await ChoiceDialog.show<ImportExerciseScoresChoice>(
      context,
      title: "Import as",
      options: [
        const ChoiceOption(
          value: ImportExerciseScoresChoice.separate,
          title: "Separate exercises",
          subtitle: "Create one exercise per imported score",
          leading: Icon(Symbols.stacks),
        ),
        const ChoiceOption(
          value: ImportExerciseScoresChoice.single,
          title: "Single exercise",
          subtitle: "Create one exercise with all the imported scores",
          leading: Icon(Symbols.dataset),
        ),
      ],
    );
  }
}
