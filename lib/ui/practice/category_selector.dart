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
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/category_name_dialog.dart';
import 'package:sheetopia/ui/practice/category_selector_viewmodel.dart';

typedef CategoryChoice = ({ExerciseCategory? category});

class CategorySelector extends StatelessWidget {
  final ExerciseCategory? category;

  /// shown when nothing is selected, e.g. "No category" or "All categories"
  final String emptyLabel;

  final String label;
  final bool allowCreate;
  final void Function(ExerciseCategory? category) onChanged;

  const CategorySelector({
    super.key,
    required this.category,
    required this.emptyLabel,
    required this.onChanged,
    this.label = "Category",
    this.allowCreate = false,
  });

  Future<void> _select(BuildContext context) async {
    final choice = await SelectCategoryDialog.show(
      context,
      selected: (category: category),
      emptyLabel: emptyLabel,
      allowCreate: allowCreate,
    );
    if (choice == null) return;
    onChanged(choice.category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = this.category;
    return InkWell(
      onTap: () => _select(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          label: Text(label),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Symbols.edit),
        ),
        child: Text(
          category?.name ?? emptyLabel,
          overflow: TextOverflow.ellipsis,
          style: category == null
              ? TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                )
              : null,
        ),
      ),
    );
  }
}

class SelectCategoryDialog extends StatefulWidget {
  static const int _maxVisibleCategories = 6;

  final CategorySelectorViewModel viewModel;

  final CategoryChoice? selected;

  final String emptyLabel;
  final bool allowCreate;

  const SelectCategoryDialog._({
    required this.viewModel,
    required this.selected,
    required this.emptyLabel,
    required this.allowCreate,
  });

  static Future<CategoryChoice?> show(
    BuildContext context, {
    required CategoryChoice? selected,
    required String emptyLabel,
    required bool allowCreate,
  }) async {
    final viewModel = CategorySelectorViewModel(repo: context.read());
    final choice = await showSheetopiaDialog<CategoryChoice>(
      context: context,
      builder: (context) => SelectCategoryDialog._(
        viewModel: viewModel,
        selected: selected,
        emptyLabel: emptyLabel,
        allowCreate: allowCreate,
      ),
    );
    viewModel.dispose();
    return choice;
  }

  @override
  State<SelectCategoryDialog> createState() => _SelectCategoryDialogState();
}

class _SelectCategoryDialogState extends State<SelectCategoryDialog> {
  late final CategorySelectorViewModel _viewModel = widget.viewModel;

  void _pick(ExerciseCategory? category) {
    Navigator.pop(context, (category: category));
  }

  Future<void> _create() async {
    final name = await CategoryNameDialog.show(
      context,
      title: "Create category",
      confirmLabel: "Create",
      initialName: _viewModel.filter.trim(),
      isTaken: _viewModel.nameTaken,
    );
    if (name == null) return;
    final category = await _viewModel.create(name);
    if (!mounted) return;
    _pick(category);
  }

  List<ExerciseCategory?> _rows() {
    final results = _viewModel.results;
    final selectedId = widget.selected?.category?.id;
    final filter = _viewModel.filter.trim().toLowerCase();
    return [
      for (final category in results)
        if (category.id == selectedId) category,
      if (filter.isEmpty || widget.emptyLabel.toLowerCase().contains(filter))
        null,
      for (final category in results)
        if (category.id != selectedId) category,
    ];
  }

  Widget _tile(ExerciseCategory? category) {
    if (category == null) {
      return RoundedListTile(
        title: widget.emptyLabel,
        titleStyle: const TextStyle(fontStyle: FontStyle.italic),
        selected: widget.selected != null && widget.selected!.category == null,
        onTap: () => _pick(null),
      );
    }
    return RoundedListTile(
      title: category.name,
      selected: widget.selected?.category?.id == category.id,
      onTap: () => _pick(category),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_viewModel.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          heightFactor: 1,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    final rows = _rows();
    if (rows.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          heightFactor: 1,
          child: Text(
            "No matching categories.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final extent = RoundedListTile.extentFor();
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            min(rows.length, SelectCategoryDialog._maxVisibleCategories + 0.5) *
            extent,
      ),
      child: ListView.builder(
        itemExtent: extent,
        padding: EdgeInsets.zero,
        itemCount: rows.length,
        itemBuilder: (context, index) => _tile(rows[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                "Select category",
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: SearchInput(
                      label: "Search",
                      onSearch: (query) => _viewModel.filter = query,
                    ),
                  ),
                  if (widget.allowCreate)
                    IconButton.outlined(
                      onPressed: _create,
                      tooltip: "Create category",
                      icon: const Icon(Symbols.add),
                    ),
                ],
              ),
              Flexible(child: _buildList(context)),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
