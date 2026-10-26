/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/metadata_filter_dialog.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/text_filter_field.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

class FilterDialog extends StatelessWidget {
  final LibraryViewModel _viewModel;

  const FilterDialog._({required this._viewModel});

  static Future<void> show(
    BuildContext context, {
    required LibraryViewModel viewModel,
  }) async {
    return await showSheetopiaDialog(
      context: context,
      builder: (context) {
        return FilterDialog._(viewModel: viewModel);
      },
    );
  }

  bool _isFiltered(ScoreField field) => switch (field) {
    ScoreField.arranger => _viewModel.filterArranger.isNotEmpty,
    ScoreField.partOf => _viewModel.filterPartOf.isNotEmpty,
    ScoreField.source => _viewModel.filterSource.isNotEmpty,
    ScoreField.difficulty => _viewModel.filterDifficulties.isNotEmpty,
    ScoreField.genres => _viewModel.filterGenres.isNotEmpty,
    _ => false,
  };

  void _clearField(ScoreField field) {
    switch (field) {
      case ScoreField.arranger:
        _viewModel.filterArranger = "";
      case ScoreField.partOf:
        _viewModel.filterPartOf = "";
      case ScoreField.source:
        _viewModel.filterSource = "";
      case ScoreField.difficulty:
        _viewModel.clearFilterDifficulties();
      case ScoreField.genres:
        _viewModel.clearFilterGenres();
      case ScoreField.composer ||
          ScoreField.instruments ||
          ScoreField.notes ||
          ScoreField.tags:
        break;
    }
  }

  Future<bool> _selectGenre(BuildContext context) async {
    final genre = await AutoCompleteInputDialog.show(
      context,
      title: "Select genre",
      inputLabel: "Genre",
      submitBtnText: "Select",
      getOptions: (filter) => _viewModel.getGenres(filter: filter),
    );
    if (genre == null) return false;
    _viewModel.addFilterGenre(genre);
    return true;
  }

  Future<void> _selectInstrument(BuildContext context) async {
    final instrument = await AutoCompleteInputDialog.show(
      context,
      title: "Select instrument",
      inputLabel: "Instrument",
      submitBtnText: "Select",
      getOptions: (filter) => _viewModel.getInstruments(filter: filter),
    );
    if (instrument == null) return;
    _viewModel.addFilterInstrument(instrument);
  }

  Widget _fieldValueWidget(
    BuildContext context,
    ScoreField field,
    bool autofocus,
  ) {
    return switch (field) {
      ScoreField.composer => TextFilterField(
        value: _viewModel.filterComposer,
        getOptions: (filter) => _viewModel.getComposers(filter: filter),
        onChanged: (value) => _viewModel.filterComposer = value,
      ),
      ScoreField.instruments => MetadataChips(
        chips: _viewModel.filterInstruments.map(
          (i) => CommonBadge(
            name: i,
            onRemove: () => _viewModel.removeFilterInstrument(i),
          ),
        ),
        addTooltip: "Select instrument",
        onAdd: () => _selectInstrument(context),
      ),
      ScoreField.tags => FilterTagsValue(
        viewModel: _viewModel,
        type: TagType.score,
      ),
      ScoreField.arranger => TextFilterField(
        value: _viewModel.filterArranger,
        autofocus: autofocus,
        getOptions: (filter) => _viewModel.getArrangers(filter: filter),
        onChanged: (value) => _viewModel.filterArranger = value,
      ),
      ScoreField.partOf => TextFilterField(
        value: _viewModel.filterPartOf,
        autofocus: autofocus,
        getOptions: (filter) => _viewModel.getPartOfs(filter: filter),
        onChanged: (value) => _viewModel.filterPartOf = value,
      ),
      ScoreField.source => TextFilterField(
        value: _viewModel.filterSource,
        autofocus: autofocus,
        getOptions: (filter) => _viewModel.getSources(filter: filter),
        onChanged: (value) => _viewModel.filterSource = value,
      ),
      ScoreField.difficulty => FilterDifficultyValue(viewModel: _viewModel),
      ScoreField.genres => MetadataChips(
        chips: _viewModel.filterGenres.map(
          (g) => CommonBadge(
            name: g,
            onRemove: () => _viewModel.removeFilterGenre(g),
          ),
        ),
        addTooltip: "Select genre",
        onAdd: () => _selectGenre(context),
      ),
      ScoreField.notes => const SizedBox(),
    };
  }

  List<Widget> _trailing(ScoreField field) => switch (field) {
    ScoreField.instruments when _viewModel.filterInstruments.isNotEmpty => [
      MatchTypeSelector(
        value: _viewModel.instrumentMatch,
        onChanged: (v) => _viewModel.instrumentMatch = v,
      ),
    ],
    ScoreField.genres when _viewModel.filterGenres.isNotEmpty => [
      MatchTypeSelector(
        value: _viewModel.genreMatch,
        onChanged: (v) => _viewModel.genreMatch = v,
      ),
    ],
    ScoreField.tags => [FilterTagMatch(viewModel: _viewModel)],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    return MetadataFilterDialog<ScoreField>(
      viewModel: _viewModel,
      permanentFields: const [
        ScoreField.composer,
        ScoreField.instruments,
        ScoreField.tags,
      ],
      optionalFields: ScoreField.filterOptional,
      isFiltered: _isFiltered,
      buildValue: (field, autofocus) =>
          _fieldValueWidget(context, field, autofocus),
      trailing: _trailing,
      onAdd: (field) async =>
          field != ScoreField.genres || await _selectGenre(context),
      clearField: _clearField,
    );
  }
}
