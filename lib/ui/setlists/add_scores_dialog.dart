/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/home/library_view.dart';

class AddScoresDialog extends StatefulWidget {
  const AddScoresDialog._();

  static Future<List<String>?> show(BuildContext context) {
    return showSheetopiaDialog<List<String>>(
      context: context,
      builder: (context) => const AddScoresDialog._(),
    );
  }

  @override
  State<AddScoresDialog> createState() => _AddScoresDialogState();
}

class _AddScoresDialogState extends State<AddScoresDialog> {
  final List<String> _selected = [];

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
            Text(
              _selected.isEmpty ? "Add scores" : "${_selected.length} selected",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall,
            ),
            Expanded(
              child: LibraryView(
                selected: _selected.toSet(),
                selectionMode: true,
                onScoreSelected: (score) => setState(() {
                  _selected.add(score.id);
                }),
                onScoreDeselected: (score) => setState(() {
                  _selected.remove(score.id);
                }),
              ),
            ),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selected),
                  child: const Text("Add"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
