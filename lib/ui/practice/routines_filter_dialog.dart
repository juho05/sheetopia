/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/add_field_button.dart';
import 'package:sheetopia/ui/common/field_section.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
import 'package:sheetopia/ui/common/text_filter_field.dart';
import 'package:sheetopia/ui/common/visible_fields.dart';
import 'package:sheetopia/ui/practice/exercise_field.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';

class RoutinesFilterDialog extends StatefulWidget {
  final PracticeRoutinesViewModel _viewModel;

  const RoutinesFilterDialog._({required this._viewModel});

  static Future<void> show(
    BuildContext context, {
    required PracticeRoutinesViewModel viewModel,
  }) async {
    return await showSheetopiaDialog(
      context: context,
      builder: (context) => RoutinesFilterDialog._(viewModel: viewModel),
    );
  }

  @override
  State<RoutinesFilterDialog> createState() => _RoutinesFilterDialogState();
}

class _RoutinesFilterDialogState extends State<RoutinesFilterDialog> {
  late final PracticeRoutinesViewModel _viewModel = widget._viewModel;
  late final VisibleFields<ExerciseField> _fields = VisibleFields(
    ExerciseField.routineFilterOptional,
  )..showWhere(_isFiltered);
  ExerciseField? _addedField;

  bool _isFiltered(ExerciseField field) =>
      field == ExerciseField.source && _viewModel.filterSource.isNotEmpty;

  void _addField(ExerciseField field) {
    setState(() {
      _addedField = field;
      _fields.show(field);
    });
  }

  void _removeField(ExerciseField field) {
    setState(() => _fields.remove(field));
    if (field == ExerciseField.source) _viewModel.filterSource = "";
  }

  List<Widget> _mainSections() {
    return [
      FieldSection(
        title: "Instrument",
        child: TextFilterField(
          value: _viewModel.filterInstrument,
          getOptions: (filter) => _viewModel.getInstruments(filter: filter),
          onChanged: (value) => _viewModel.filterInstrument = value,
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
          type: TagType.exercise,
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

  Widget _filterCard(ExerciseField field) {
    return FieldSection(
      title: field.label,
      trailing: [RemoveFieldButton(onPressed: () => _removeField(field))],
      child: switch (field) {
        ExerciseField.source => TextFilterField(
          value: _viewModel.filterSource,
          autofocus: _addedField == field,
          getOptions: (filter) => _viewModel.getSources(filter: filter),
          onChanged: (value) => _viewModel.filterSource = value,
        ),
        _ => const SizedBox(),
      },
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
                      onPressed: () => Navigator.pop(context),
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
