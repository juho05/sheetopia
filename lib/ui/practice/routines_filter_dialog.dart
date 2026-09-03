/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/select_tags_list.dart';
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
  late final TextEditingController _instrumentController =
      TextEditingController(text: _viewModel.filterInstrument);
  final FocusNode _instrumentFocus = FocusNode();
  late final TextEditingController _sourceController = TextEditingController(
    text: _viewModel.filterSource,
  );
  final FocusNode _sourceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onFiltersChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onFiltersChanged);
    _instrumentController.dispose();
    _instrumentFocus.dispose();
    _sourceController.dispose();
    _sourceFocus.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (_viewModel.filterInstrument.isEmpty &&
        _instrumentController.text.isNotEmpty) {
      _instrumentController.clear();
    }
    if (_viewModel.filterSource.isEmpty && _sourceController.text.isNotEmpty) {
      _sourceController.clear();
    }
  }

  Future<void> _addTags() async {
    final tags = await AddTagsDialog.show(
      context,
      alreadySelected: _viewModel.filterTags.toSet(),
      enableTagEdits: false,
      type: TagType.exercise,
      title: "Select tags",
      addBtnText: "Select",
    );
    if (tags == null || tags.isEmpty) return;
    _viewModel.addFilterTags(tags);
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
                  padding: const EdgeInsets.only(top: 12),
                  child: AutoCompleteField(
                    controller: _instrumentController,
                    focusNode: _instrumentFocus,
                    getOptions: (filter) =>
                        _viewModel.getInstruments(filter: filter),
                    onChanged: (value) =>
                        _viewModel.filterInstrument = value.trim(),
                    onSelected: (option) =>
                        _viewModel.filterInstrument = option.trim(),
                    decoration: InputDecoration(
                      label: const Text("Instrument"),
                      border: const OutlineInputBorder(),
                      suffixIcon: _viewModel.filterInstrument.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _instrumentController.clear();
                                _viewModel.filterInstrument = "";
                                _instrumentFocus.unfocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AutoCompleteField(
                    controller: _sourceController,
                    focusNode: _sourceFocus,
                    getOptions: (filter) =>
                        _viewModel.getSources(filter: filter),
                    onChanged: (value) => _viewModel.filterSource = value.trim(),
                    onSelected: (option) =>
                        _viewModel.filterSource = option.trim(),
                    decoration: InputDecoration(
                      label: const Text("Source"),
                      border: const OutlineInputBorder(),
                      suffixIcon: _viewModel.filterSource.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _sourceController.clear();
                                _viewModel.filterSource = "";
                                _sourceFocus.unfocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Row(
                    children: [
                      const Expanded(child: Heading(text: "Tags")),
                      if (_viewModel.filterTags.isNotEmpty)
                        MatchTypeSelector(
                          value: _viewModel.tagMatch,
                          onChanged: (v) => _viewModel.tagMatch = v,
                        ),
                    ],
                  ),
                ),
                SelectTagsList(
                  tags: _viewModel.filterTags.map(
                    (t) => TagBadge(
                      tag: t,
                      onRemove: () => _viewModel.removeFilterTag(t),
                    ),
                  ),
                  onAdd: _addTags,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _viewModel.hasFilters
                          ? _viewModel.clearFilters
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
