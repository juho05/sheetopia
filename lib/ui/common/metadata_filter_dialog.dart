/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/add_field_row.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/common/filter_viewmodel.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
import 'package:sheetopia/ui/common/visible_fields.dart';

class MetadataFilterDialog<T extends MetadataField> extends StatefulWidget {
  final FilterViewModel viewModel;
  final List<T> permanentFields;
  final List<T> optionalFields;
  final bool Function(T field) isFiltered;

  final Widget Function(T field, bool autofocus) buildValue;
  final List<Widget> Function(T field)? trailing;

  /// returning false from this cancels adding the field
  final Future<bool> Function(T field)? onAdd;
  final void Function(T field) clearField;

  const MetadataFilterDialog({
    super.key,
    required this.viewModel,
    required this.permanentFields,
    required this.optionalFields,
    required this.isFiltered,
    required this.buildValue,
    this.trailing,
    this.onAdd,
    required this.clearField,
  });

  @override
  State<MetadataFilterDialog<T>> createState() =>
      _MetadataFilterDialogState<T>();
}

class _MetadataFilterDialogState<T extends MetadataField>
    extends State<MetadataFilterDialog<T>> {
  FilterViewModel get _viewModel => widget.viewModel;

  late final VisibleFields<T> _fields = VisibleFields(
    widget.optionalFields,
    isFilled: widget.isFiltered,
  )..showFilled();
  T? _addedField;

  Future<void> _add(T field) async {
    if (widget.onAdd != null && !await widget.onAdd!(field)) return;
    setState(() {
      _addedField = field;
      _fields.show(field);
    });
  }

  void _remove(T field) {
    setState(() => _fields.remove(field));
    widget.clearField(field);
  }

  Widget _row(T field, {required bool optional}) {
    return MetadataRow.field(
      field,
      trailing: widget.trailing?.call(field) ?? const [],
      onRemove: optional ? () => _remove(field) : null,
      child: widget.buildValue(field, _addedField == field),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final field in widget.permanentFields)
                      _row(field, optional: false),
                    for (final field in widget.optionalFields)
                      if (_fields.isVisible(field)) _row(field, optional: true),
                    if (_fields.hidden.isNotEmpty)
                      AddFieldRow(
                        label: "Add filter",
                        fields: _fields.hidden,
                        onSelected: _add,
                      ),
                  ],
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

class FilterTagsValue extends StatelessWidget {
  final FilterViewModel viewModel;
  final TagType type;

  const FilterTagsValue({
    super.key,
    required this.viewModel,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return TagSelector(
      tags: viewModel.filterTags,
      type: type,
      enableCreateTagFromSearch: false,
      dialogTitle: "Select tags",
      addBtnText: "Select",
      onAdd: viewModel.addFilterTags,
      onRemove: viewModel.removeFilterTag,
      onSynced: viewModel.setFilterTags,
    );
  }
}

class FilterTagMatch extends StatelessWidget {
  final FilterViewModel viewModel;

  const FilterTagMatch({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.filterTags.isEmpty) return const SizedBox.shrink();
    return MatchTypeSelector(
      value: viewModel.tagMatch,
      onChanged: (v) => viewModel.tagMatch = v,
    );
  }
}

class FilterDifficultyValue extends StatelessWidget {
  final FilterViewModel viewModel;

  const FilterDifficultyValue({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return DifficultySelector.multi(
      values: viewModel.filterDifficulties,
      onToggle: viewModel.toggleFilterDifficulty,
      includeNone: true,
    );
  }
}
