/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/bulk_edit/bulk_edit_metadata_dialog.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/bulk_edit/bulk_edit_menu_viewmodel.dart';
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

  Future<void> _editMetadata() async {
    final count = widget.selectedScoreIds.length;
    final edit = await BulkEditMetadataDialog.show(
      context,
      title: "Edit metadata of $count ${count == 1 ? "score" : "scores"}",
      fields: [
        BulkMetadataField(
          ScoreField.composer,
          BulkInputKind.text,
          getOptions: (filter, _) => _viewModel.getComposers(filter: filter),
        ),
        BulkMetadataField(
          ScoreField.arranger,
          BulkInputKind.text,
          getOptions: (filter, _) => _viewModel.getArrangers(filter: filter),
        ),
        BulkMetadataField(
          ScoreField.partOf,
          BulkInputKind.text,
          getOptions: (filter, _) => _viewModel.getPartOfs(filter: filter),
        ),
        const BulkMetadataField(
          ScoreField.musicalKey,
          BulkInputKind.musicalKey,
        ),
        BulkMetadataField(
          ScoreField.source,
          BulkInputKind.source,
          getOptions: (filter, _) => _viewModel.getSources(filter: filter),
        ),
        const BulkMetadataField(
          ScoreField.difficulty,
          BulkInputKind.difficulty,
        ),
        BulkMetadataField(
          ScoreField.instruments,
          BulkInputKind.valueList,
          valueLabel: "Instrument",
          getOptions: (filter, exclude) =>
              _viewModel.getInstruments(filter: filter, exclude: exclude),
        ),
        BulkMetadataField(
          ScoreField.genres,
          BulkInputKind.valueList,
          valueLabel: "Genre",
          getOptions: (filter, exclude) =>
              _viewModel.getGenres(filter: filter, exclude: exclude),
        ),
        const BulkMetadataField(ScoreField.tags, BulkInputKind.tags),
      ],
    );
    if (edit == null) return;
    switch (edit) {
      case BulkTextEdit(field: ScoreField.arranger, :final value):
        await _viewModel.editArranger(value);
      case BulkTextEdit(field: ScoreField.partOf, :final value):
        await _viewModel.editPartOf(value);
      case BulkTextEdit(:final value):
        await _viewModel.editComposer(value);
      case BulkSourceEdit(:final source, :final sourceLink):
        await _viewModel.editSource(source, sourceLink);
      case BulkDifficultyEdit(:final difficulty):
        await _viewModel.editDifficulty(difficulty);
      case BulkMusicalKeyEdit(:final musicalKey):
        await _viewModel.editMusicalKey(musicalKey);
      case BulkValuesEdit(field: ScoreField.genres, :final add, :final remove):
        await _viewModel.editGenres(add, remove);
      case BulkValuesEdit(:final add, :final remove):
        await _viewModel.editInstruments(add, remove);
      case BulkTagsEdit(:final addIds, :final removeIds):
        await _viewModel.editTags(addIds.toSet(), removeIds.toSet());
      case BulkCategoryEdit():
        return;
    }
    Toast.show(
      edit.field == ScoreField.partOf
          ? 'Successfully updated "Part of" for selected scores'
          : "Successfully updated ${edit.field.label.toLowerCase()} of selected scores",
    );
  }

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Edit metadata",
          icon: Symbols.edit_note,
          onSelected: (_) => _editMetadata(),
        ),
        ContextMenuOption(
          title: "Add to setlist",
          icon: Icons.playlist_add,
          onSelected: (_) async {
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
          onSelected: (_) => _delete(),
        ),
      ],
    );
  }
}
