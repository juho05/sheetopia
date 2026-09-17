/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';

enum ImportSource { file, scan }

class ImportSourceDialog {
  static bool get scanSupported => Platform.isAndroid || Platform.isIOS;

  static Future<ImportSource?> show(
    BuildContext context, {
    String title = "Import score",
  }) {
    if (!scanSupported) return Future.value(ImportSource.file);
    return ChoiceDialog.show<ImportSource>(
      context,
      title: title,
      options: const [
        ChoiceOption(
          value: ImportSource.file,
          title: "Import files",
          leading: Icon(Icons.file_open),
        ),
        ChoiceOption(
          value: ImportSource.scan,
          title: "Scan pages",
          leading: Icon(Icons.document_scanner),
        ),
      ],
    );
  }
}
