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
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/match_type_selector.dart';
import 'package:sheetopia/ui/common/select_tags_list.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
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
  late final TextEditingController _composerController = TextEditingController(
    text: _viewModel.filterComposer,
  );
  final FocusNode _composerFocus = FocusNode();
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
    _composerController.dispose();
    _composerFocus.dispose();
    _sourceController.dispose();
    _sourceFocus.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    if (_viewModel.filterComposer.isEmpty &&
        _composerController.text.isNotEmpty) {
      _composerController.clear();
    }
    if (_viewModel.filterSource.isEmpty && _sourceController.text.isNotEmpty) {
      _sourceController.clear();
    }
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
                    controller: _composerController,
                    focusNode: _composerFocus,
                    getOptions: (filter) =>
                        _viewModel.getComposers(filter: filter),
                    onChanged: (value) =>
                        _viewModel.filterComposer = value.trim(),
                    onSelected: (option) =>
                        _viewModel.filterComposer = option.trim(),
                    decoration: InputDecoration(
                      label: const Text("Composer"),
                      border: const OutlineInputBorder(),
                      suffixIcon: _viewModel.filterComposer.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _composerController.clear();
                                _viewModel.filterComposer = "";
                                _composerFocus.unfocus();
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
                    onChanged: (value) =>
                        _viewModel.filterSource = value.trim(),
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
                      const Expanded(child: Heading(text: "Instruments")),
                      if (_viewModel.filterInstruments.isNotEmpty)
                        MatchTypeSelector(
                          value: _viewModel.instrumentMatch,
                          onChanged: (v) => _viewModel.instrumentMatch = v,
                        ),
                    ],
                  ),
                ),
                SelectTagsList(
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
                      getOptions: (filter) =>
                          _viewModel.getInstruments(filter: filter),
                    );
                    if (instrument == null) return;
                    _viewModel.addFilterInstrument(instrument);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Row(
                    children: [
                      const Expanded(child: Heading(text: "Genres")),
                      if (_viewModel.filterGenres.isNotEmpty)
                        MatchTypeSelector(
                          value: _viewModel.genreMatch,
                          onChanged: (v) => _viewModel.genreMatch = v,
                        ),
                    ],
                  ),
                ),
                SelectTagsList(
                  tags: _viewModel.filterGenres.map(
                    (g) => CommonBadge(
                      name: g,
                      onRemove: () {
                        _viewModel.removeFilterGenre(g);
                      },
                    ),
                  ),
                  onAdd: () async {
                    final genre = await AutoCompleteInputDialog.show(
                      context,
                      title: "Select genre",
                      inputLabel: "Genre",
                      submitBtnText: "Select",
                      getOptions: (filter) =>
                          _viewModel.getGenres(filter: filter),
                    );
                    if (genre == null) return;
                    _viewModel.addFilterGenre(genre);
                  },
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
                TagSelector(
                  tags: _viewModel.filterTags,
                  type: TagType.score,
                  enableCreateTagFromSearch: false,
                  dialogTitle: "Select tags",
                  addBtnText: "Select",
                  onAdd: _viewModel.addFilterTags,
                  onRemove: _viewModel.removeFilterTag,
                  onSynced: _viewModel.setFilterTags,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          _viewModel.filterTags.isNotEmpty ||
                              _viewModel.filterGenres.isNotEmpty ||
                              _viewModel.filterInstruments.isNotEmpty ||
                              _viewModel.filterComposer.isNotEmpty ||
                              _viewModel.filterSource.isNotEmpty
                          ? () {
                              _viewModel.clearFilters();
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
