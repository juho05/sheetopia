/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/selection/select_all_button.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/home/library_view.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

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
  final SelectionModel _selected = SelectionModel();

  late final LibraryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LibraryViewModel(repo: context.read());
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
                        ? "Add scores"
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
                      await _viewModel.getFilteredScoreIds(),
                    ),
                    onClearSelection: _selected.clear,
                  ),
                ),
              ],
            ),
            Expanded(
              child: LibraryView(
                viewModel: _viewModel,
                selected: _selected.idSet,
                selectionMode: true,
                onScoreSelected: (score) => _selected.select(score.id),
                onScoreDeselected: (score) => _selected.deselect(score.id),
                onScoresSelected: _selected.selectAll,
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
                      : () => Navigator.pop(context, [..._selected.ids]),
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
