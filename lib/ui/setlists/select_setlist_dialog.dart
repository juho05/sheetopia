/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/setlists/setlist.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/setlists/setlists_viewmodel.dart';

class SelectSetlistDialog extends StatefulWidget {
  static const double _itemExtent = 64;

  final String title;

  const SelectSetlistDialog._({required this.title});

  static Future<Setlist?> show(
    BuildContext context, {
    String title = "Select setlist",
  }) {
    return showSheetopiaDialog<Setlist>(
      context: context,
      builder: (context) => SelectSetlistDialog._(title: title),
    );
  }

  @override
  State<SelectSetlistDialog> createState() => _SelectSetlistDialogState();
}

class _SelectSetlistDialogState extends State<SelectSetlistDialog> {
  late final SetlistsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SetlistsViewModel(repo: context.read());
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
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          SearchInput(
            label: "Search",
            debounce: const Duration(milliseconds: 50),
            onSearch: (query) {
              _viewModel.filterSearch = query;
            },
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => _buildContent(context),
            ),
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

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (_viewModel.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    if (_viewModel.setlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _viewModel.isFiltered ? "No setlists found." : "No setlists yet.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            max(1, _viewModel.setlists.length) *
            SelectSetlistDialog._itemExtent,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView.builder(
          itemExtent: SelectSetlistDialog._itemExtent,
          padding: EdgeInsets.zero,
          itemCount: _viewModel.setlists.length,
          itemBuilder: (context, index) {
            final setlist = _viewModel.setlists[index];
            return ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(setlist.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                "${setlist.entryCount} "
                "${setlist.entryCount == 1 ? "score" : "scores"}",
              ),
              onTap: () => Navigator.pop(context, setlist),
            );
          },
        ),
      ),
    );
  }
}