/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/bulk_edit/bulk_edit_menu_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/source_input_dialog.dart';
import 'package:sheetopia/ui/common/bulk_edit/bulk_edit_tags_dialog.dart';
import 'package:sheetopia/ui/common/bulk_edit/bulk_edit_values_dialog.dart';
import 'package:sheetopia/ui/setlists/select_setlist_dialog.dart';

class BulkEditMenu extends StatefulWidget {
  final List<String> selectedScoreIds;
  final void Function()? onDeleted;

  const BulkEditMenu({
    super.key,
    required this.selectedScoreIds,
    this.onDeleted,
  });

  @override
  State<BulkEditMenu> createState() => _BulkEditMenuState();
}

class _BulkEditMenuState extends State<BulkEditMenu> {
  late final BulkEditMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BulkEditMenuViewModel(
      repo: context.read(),
      setlistsRepo: context.read(),
      selectedScores: widget.selectedScoreIds,
    );
  }

  @override
  void didUpdateWidget(covariant BulkEditMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _viewModel.updateSelectedScores(widget.selectedScoreIds);
  }

  Future<void> _delete() async {
    final count = widget.selectedScoreIds.length;
    final scores = count == 1 ? "score" : "scores";
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete $count $scores?",
      message:
          "They will be deleted on all your devices and removed from "
          "every setlist and exercise that uses them.",
    );
    if (!confirmed) return;
    final deleted = await _viewModel.delete();
    widget.onDeleted?.call();
    Toast.show("Deleted $deleted ${deleted == 1 ? "score" : "scores"}");
  }

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Edit composer",
          icon: Symbols.artist,
          onSelected: () async {
            final composer = await AutoCompleteInputDialog.show(
              context,
              title: "Bulk edit composer",
              inputLabel: "Composer",
              submitBtnText: "Update",
              enableClear: true,
              getOptions: (filter) => _viewModel.getComposers(filter: filter),
            );
            if (composer == null) return;
            await _viewModel.editComposer(composer);
            Toast.show("Successfully updated composer of selected scores");
          },
        ),
        ContextMenuOption(
          title: "Edit source",
          icon: Symbols.link,
          onSelected: () async {
            final result = await SourceInputDialog.show(
              context,
              title: "Bulk edit source",
              submitBtnText: "Update",
              enableClear: true,
              getOptions: (filter) => _viewModel.getSources(filter: filter),
            );
            if (result == null) return;
            await _viewModel.editSource(result.source, result.sourceLink);
            Toast.show("Successfully updated source of selected scores");
          },
        ),
        ContextMenuOption(
          title: "Edit instruments",
          icon: Symbols.piano,
          onSelected: () async {
            final result = await BulkEditValuesDialog.show(
              context,
              title: "Bulk edit instruments",
              valuesLabel: "instruments",
              inputLabel: "Instrument",
              getOptions: (filter, exclude) =>
                  _viewModel.getInstruments(filter: filter, exclude: exclude),
            );
            if (result == null) return;
            await _viewModel.editInstruments(result.add, result.remove);
            Toast.show("Successfully updated instruments of selected scores");
          },
        ),
        ContextMenuOption(
          title: "Edit genres",
          icon: Symbols.genres,
          onSelected: () async {
            final result = await BulkEditValuesDialog.show(
              context,
              title: "Bulk edit genres",
              valuesLabel: "genres",
              inputLabel: "Genre",
              getOptions: (filter, exclude) =>
                  _viewModel.getGenres(filter: filter, exclude: exclude),
            );
            if (result == null) return;
            await _viewModel.editGenres(result.add, result.remove);
            Toast.show("Successfully updated genres of selected scores");
          },
        ),
        ContextMenuOption(
          title: "Edit tags",
          icon: Symbols.label,
          onSelected: () async {
            final result = await BulkEditTagsDialog.show(context);
            if (result == null) return;
            await _viewModel.editTags(
              result.addIds.toSet(),
              result.removeIds.toSet(),
            );
            Toast.show("Successfully updated tags of selected scores");
          },
        ),
        ContextMenuOption(
          title: "Add to setlist",
          icon: Icons.playlist_add,
          onSelected: () async {
            final setlist = await SelectSetlistDialog.show(
              context,
              title: "Add to setlist",
            );
            if (setlist == null) return;
            final count = await _viewModel.addToSetlist(setlist.id);
            Toast.show(
              "Added $count ${count == 1 ? "score" : "scores"} "
              "to \"${setlist.name}\"",
            );
          },
        ),
        ContextMenuOption(
          title: "Delete",
          icon: Symbols.delete,
          onSelected: _delete,
        ),
      ],
    );
  }
}
