/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

enum ImportSource { file, scan }

class ImportSourceDialog extends StatelessWidget {
  static const double _optionHeight = 72;

  final String title;

  const ImportSourceDialog._({required this.title});

  static bool get scanSupported => Platform.isAndroid || Platform.isIOS;

  static Future<ImportSource?> show(
    BuildContext context, {
    String title = "Import score",
  }) {
    if (!scanSupported) return Future.value(ImportSource.file);
    return showSheetopiaDialog<ImportSource>(
      context: context,
      builder: (context) => ImportSourceDialog._(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          RoundedListTile(
            title: "Import files",
            tooltip: false,
            height: _optionHeight,
            leading: const Icon(Icons.file_open),
            onTap: () => Navigator.pop(context, ImportSource.file),
          ),
          RoundedListTile(
            title: "Scan pages",
            tooltip: false,
            height: _optionHeight,
            leading: const Icon(Icons.document_scanner),
            onTap: () => Navigator.pop(context, ImportSource.scan),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
