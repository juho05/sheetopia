/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/setlists/setlist.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/setlists/setlist_name_dialog.dart';
import 'package:sheetopia/ui/setlists/setlists_viewmodel.dart';

class SetlistsView extends StatefulWidget {
  const SetlistsView({super.key});

  @override
  State<SetlistsView> createState() => _SetlistsViewState();
}

class _SetlistsViewState extends State<SetlistsView> {
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

  Future<void> _create() async {
    final repo = context.read<SetlistsRepository>();
    final name = await SetlistNameDialog.show(
      context,
      title: "New setlist",
      confirmLabel: "Create",
    );
    if (name == null) return;
    await repo.createSetlist(name: name);
  }

  Future<void> _rename(Setlist setlist) async {
    final name = await SetlistNameDialog.show(
      context,
      title: "Rename setlist",
      confirmLabel: "Rename",
      initialName: setlist.name,
    );
    if (name == null) return;
    await _viewModel.rename(setlist.id, name);
  }

  Future<void> _delete(Setlist setlist) async {
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete setlist?",
      message:
          "\"${setlist.name}\" will be deleted on all your devices. "
          "The scores in it are not deleted.",
    );
    if (!confirmed) return;
    await _viewModel.delete(setlist.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
          child: SearchInput(
            label: "Search",
            onSearch: (query) {
              _viewModel.filterSearch = query;
            },
          ),
        ),
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _buildCountLabel(context),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => _buildContent(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCountLabel(BuildContext context) {
    final count = _viewModel.resultCount;
    if (count == null) return const SizedBox.shrink();
    final total = _viewModel.totalCount;
    if (total == 0) return const SizedBox.shrink();
    final label = _viewModel.isFiltered && total != null && total != count
        ? "$count of $total"
        : "$count ${count == 1 ? "setlist" : "setlists"}";
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_viewModel.setlists.isEmpty) {
      if (_viewModel.isFiltered) {
        return Center(
          child: Text(
            "No matching setlists.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(
              "No setlists yet.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text("New setlist"),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemExtent: RoundedListTile.extentFor(subtitle: true),
      itemCount: _viewModel.setlists.length,
      itemBuilder: (context, index) {
        final setlist = _viewModel.setlists[index];
        return RoundedListTile(
          leading: const RoundedTileIcon(icon: Icons.queue_music),
          title: setlist.name,
          subtitle: Text(
            "${setlist.entryCount} "
            "${setlist.entryCount == 1 ? "score" : "scores"}",
          ),
          onTap: () => context.go("/setlists/${setlist.id}"),
          trailing: MenuButton(
            options: [
              ContextMenuOption(
                icon: Icons.edit,
                title: "Rename",
                onSelected: () => _rename(setlist),
              ),
              ContextMenuOption(
                icon: Icons.delete,
                title: "Delete",
                onSelected: () => _delete(setlist),
              ),
            ],
          ),
        );
      },
    );
  }
}
