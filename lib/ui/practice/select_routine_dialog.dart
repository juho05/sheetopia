/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';

class SelectRoutineDialog extends StatefulWidget {
  static const int _maxVisibleRoutines = 6;

  final String title;

  const SelectRoutineDialog._({required this.title});

  static Future<PracticeRoutine?> show(
    BuildContext context, {
    String title = "Select routine",
  }) {
    return showSheetopiaDialog<PracticeRoutine>(
      context: context,
      builder: (context) => SelectRoutineDialog._(title: title),
    );
  }

  @override
  State<SelectRoutineDialog> createState() => _SelectRoutineDialogState();
}

class _SelectRoutineDialogState extends State<SelectRoutineDialog> {
  late final PracticeRoutinesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeRoutinesViewModel(
      repo: context.read(),
      scoresRepo: context.read(),
    );
    _viewModel.loadNextPage();
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
    final routines = _viewModel.routines;
    if (routines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _viewModel.isFiltered ? "No routines found." : "No routines yet.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final extent = RoundedListTile.extentFor(subtitle: true);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            min(
              routines.length,
              SelectRoutineDialog._maxVisibleRoutines + 0.5,
            ) *
            extent,
      ),
      child: ListView.builder(
        itemExtent: extent,
        padding: EdgeInsets.zero,
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          return RoundedListTile(
            leading: const RoundedTileIcon(icon: Symbols.checklist),
            title: routine.name,
            subtitle: Text(
              routineSummary(routine.exerciseCount, routine.targetDuration),
            ),
            onTap: () => Navigator.pop(context, routine),
          );
        },
      ),
    );
  }
}
