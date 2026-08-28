/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/category_name_dialog.dart';
import 'package:sheetopia/ui/practice/manage_categories_viewmodel.dart';

class ManageCategoriesDialog extends StatefulWidget {
  static const int _maxVisibleCategories = 5;

  final ManageCategoriesViewModel viewModel;

  const ManageCategoriesDialog._({required this.viewModel});

  static Future<void> show(BuildContext context) async {
    final viewModel = ManageCategoriesViewModel(repo: context.read());
    await showSheetopiaDialog(
      context: context,
      builder: (context) => ManageCategoriesDialog._(viewModel: viewModel),
    );
    viewModel.dispose();
  }

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  late final ManageCategoriesViewModel _viewModel = widget.viewModel;

  Future<void> _create() async {
    final name = await CategoryNameDialog.show(
      context,
      title: "Create category",
      confirmLabel: "Create",
      isTaken: (name) => _viewModel.nameTaken(name),
    );
    if (name == null) return;
    await _viewModel.create(name);
  }

  Future<void> _rename(CategoryEntry entry) async {
    final name = await CategoryNameDialog.show(
      context,
      title: "Rename category",
      confirmLabel: "Rename",
      initialName: entry.category.name,
      isTaken: (name) =>
          _viewModel.nameTaken(name, exceptId: entry.category.id),
    );
    if (name == null || name == entry.category.name) return;
    await _viewModel.rename(entry.category.id, name);
  }

  Future<void> _delete(CategoryEntry entry) async {
    final count = entry.exerciseCount;
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete \"${entry.category.name}\"?",
      message: count == 0
          ? null
          : "${count == 1 ? "1 exercise" : "$count exercises"} will no longer "
                "have a category.",
    );
    if (!confirmed) return;
    await _viewModel.delete(entry.category.id);
  }

  Widget _categoryTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final entry = _viewModel.categories[index];
    final count = entry.exerciseCount;
    return ReorderableDelayedDragStartListener(
      key: ValueKey(entry.category.id),
      index: index,
      child: RoundedListTile(
        tooltip: false,
        leading: ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Icon(Icons.drag_handle),
          ),
        ),
        title: entry.category.name,
        subtitle: Text(
          count == 0
              ? "No exercises"
              : "$count ${count == 1 ? "exercise" : "exercises"}",
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: MenuButton(
          options: [
            ContextMenuOption(
              icon: Symbols.edit,
              title: "Rename",
              onSelected: () => _rename(entry),
            ),
            ContextMenuOption(
              icon: Symbols.delete,
              title: "Delete",
              onSelected: () => _delete(entry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    if (_viewModel.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          heightFactor: 1,
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }
    if (_viewModel.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          heightFactor: 1,
          child: Text(
            "No categories yet.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final extent = RoundedListTile.extentFor(subtitle: true);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            min(
              _viewModel.categories.length,
              ManageCategoriesDialog._maxVisibleCategories,
            ) *
            extent,
      ),
      child: ReorderableListView.builder(
        itemExtent: extent,
        padding: EdgeInsets.zero,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) =>
            Material(type: MaterialType.transparency, child: child),
        itemCount: _viewModel.categories.length,
        itemBuilder: _categoryTile,
        onReorderItem: _viewModel.move,
        onReorderStart: (_) {
          HapticFeedback.lightImpact();
        },
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
                "Categories",
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              Flexible(child: _buildList(context)),
              Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _create,
                    icon: const Icon(Symbols.add),
                    label: const Text("Create"),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done"),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
