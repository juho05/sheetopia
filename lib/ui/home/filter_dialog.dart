/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/add_field_button.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/common/field_section.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/common/select_tags_list.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
import 'package:sheetopia/ui/common/text_filter_field.dart';
import 'package:sheetopia/ui/common/visible_fields.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

class FilterDialog extends StatefulWidget {
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

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late final LibraryViewModel _viewModel = widget._viewModel;
  late final VisibleFields<ScoreField> _fields = VisibleFields(
    ScoreField.filterOptional,
  )..showWhere(_isFiltered);
  ScoreField? _addedField;

  bool _isFiltered(ScoreField field) => switch (field) {
    ScoreField.arranger => _viewModel.filterArranger.isNotEmpty,
    ScoreField.source => _viewModel.filterSource.isNotEmpty,
    ScoreField.difficulty => _viewModel.filterDifficulties.isNotEmpty,
    ScoreField.genres => _viewModel.filterGenres.isNotEmpty,
    _ => false,
  };

  Future<void> _addField(ScoreField field) async {
    switch (field) {
      case ScoreField.arranger || ScoreField.source:
        setState(() {
          _addedField = field;
          _fields.show(field);
        });
      case ScoreField.difficulty:
        if (await _selectDifficulty()) setState(() => _fields.show(field));
      case ScoreField.genres:
        if (await _selectGenre()) setState(() => _fields.show(field));
      case ScoreField.composer ||
          ScoreField.instruments ||
          ScoreField.notes ||
          ScoreField.tags:
        break;
    }
  }

  void _removeField(ScoreField field) {
    setState(() => _fields.remove(field));
    switch (field) {
      case ScoreField.arranger:
        _viewModel.filterArranger = "";
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

  Future<bool> _selectDifficulty() async {
    final difficulty = await showDifficultyPicker(
      context,
      title: "Select difficulty",
      exclude: _viewModel.filterDifficulties,
    );
    if (difficulty == null) return false;
    _viewModel.toggleFilterDifficulty(difficulty, true);
    return true;
  }

  Future<bool> _selectGenre() async {
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

  List<Widget> _mainSections() {
    return [
      FieldSection(
        title: "Composer",
        child: TextFilterField(
          value: _viewModel.filterComposer,
          getOptions: (filter) => _viewModel.getComposers(filter: filter),
          onChanged: (value) => _viewModel.filterComposer = value,
        ),
      ),
      FieldSection(
        title: "Instruments",
        badges: true,
        trailing: [
          if (_viewModel.filterInstruments.isNotEmpty)
            MatchTypeSelector(
              value: _viewModel.instrumentMatch,
              onChanged: (v) => _viewModel.instrumentMatch = v,
            ),
        ],
        child: SelectTagsList(
          tags: _viewModel.filterInstruments.map(
            (i) => CommonBadge(
              name: i,
              onRemove: () {
                _viewModel.removeFilterInstrument(i);
              },
            ),
          ),
          onAdd: () async {
            final instrument = await AutoCompleteInputDialog.show(
              context,
              title: "Select instrument",
              inputLabel: "Instrument",
              submitBtnText: "Select",
              getOptions: (filter) => _viewModel.getInstruments(filter: filter),
            );
            if (instrument == null) return;
            _viewModel.addFilterInstrument(instrument);
          },
        ),
      ),
      FieldSection(
        title: "Tags",
        badges: true,
        trailing: [
          if (_viewModel.filterTags.isNotEmpty)
            MatchTypeSelector(
              value: _viewModel.tagMatch,
              onChanged: (v) => _viewModel.tagMatch = v,
            ),
        ],
        child: TagSelector(
          tags: _viewModel.filterTags,
          type: TagType.score,
          enableCreateTagFromSearch: false,
          dialogTitle: "Select tags",
          addBtnText: "Select",
          onAdd: _viewModel.addFilterTags,
          onRemove: _viewModel.removeFilterTag,
          onSynced: _viewModel.setFilterTags,
        ),
      ),
    ];
  }

  Widget _filterCard(ScoreField field) {
    final Widget input = switch (field) {
      ScoreField.arranger => TextFilterField(
        value: _viewModel.filterArranger,
        autofocus: _addedField == field,
        getOptions: (filter) => _viewModel.getArrangers(filter: filter),
        onChanged: (value) => _viewModel.filterArranger = value,
      ),
      ScoreField.source => TextFilterField(
        value: _viewModel.filterSource,
        autofocus: _addedField == field,
        getOptions: (filter) => _viewModel.getSources(filter: filter),
        onChanged: (value) => _viewModel.filterSource = value,
      ),
      ScoreField.difficulty => SelectTagsList(
        tags: [
          for (final d in _viewModel.filterDifficulties)
            DifficultyBadge(
              difficulty: d,
              onRemove: () => _viewModel.toggleFilterDifficulty(d, false),
            ),
        ],
        onAdd: _viewModel.filterDifficulties.length < Difficulty.values.length
            ? _selectDifficulty
            : null,
      ),
      ScoreField.genres => SelectTagsList(
        tags: _viewModel.filterGenres.map(
          (g) => CommonBadge(
            name: g,
            onRemove: () {
              _viewModel.removeFilterGenre(g);
            },
          ),
        ),
        onAdd: _selectGenre,
      ),
      _ => const SizedBox(),
    };
    return FieldSection(
      title: field.label,
      badges: field == ScoreField.difficulty || field == ScoreField.genres,
      trailing: [
        if (field == ScoreField.genres && _viewModel.filterGenres.isNotEmpty)
          MatchTypeSelector(
            value: _viewModel.genreMatch,
            onChanged: (v) => _viewModel.genreMatch = v,
          ),
        RemoveFieldButton(onPressed: () => _removeField(field)),
      ],
      child: input,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: SingleChildScrollView(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Filter",
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      ..._mainSections(),
                      for (final field in _fields.visible) _filterCard(field),
                      if (_fields.hidden.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: FieldSection.headingInset,
                          ),
                          child: AddFieldButton(
                            label: "Add filter",
                            fields: _fields.hidden,
                            onSelected: _addField,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _viewModel.hasFilters
                          ? () {
                              _viewModel.clearFilters();
                              setState(_fields.clear);
                            }
                          : null,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text("Clear"),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
