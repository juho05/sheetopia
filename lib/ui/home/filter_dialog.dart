import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/select_tags_list.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

class FilterDialog extends StatelessWidget {
  final LibraryViewModel _viewModel;

  const FilterDialog._({required LibraryViewModel viewModel})
    : _viewModel = viewModel;

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
                  child: Autocomplete(
                    optionsBuilder: (textEditingValue) =>
                        _viewModel.getComposers(filter: textEditingValue.text),
                    onSelected: (option) =>
                        _viewModel.filterComposer = option.trim(),
                    initialValue: TextEditingValue(
                      text: _viewModel.filterComposer,
                    ),
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) => TextField(
                          onTapOutside: (event) => focusNode.unfocus(),
                          controller: textEditingController,
                          onChanged: (value) =>
                              _viewModel.filterComposer = value.trim(),
                          focusNode: focusNode,
                          onSubmitted: (control) {
                            onFieldSubmitted();
                          },
                          decoration: const InputDecoration(
                            label: Text("Composer"),
                            border: OutlineInputBorder(),
                          ),
                        ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Heading(text: "Instruments"),
                ),
                SelectTagsList(
                  tags: _viewModel.filterInstruments.map(
                    (i) => CommonBadge(
                      name: i,
                      onDialog: true,
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
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Heading(text: "Genres"),
                ),
                SelectTagsList(
                  tags: _viewModel.filterGenres.map(
                    (g) => CommonBadge(
                      name: g,
                      onDialog: true,
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
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 4),
                  child: Heading(text: "Tags"),
                ),
                SelectTagsList(
                  tags: _viewModel.filterTags.map(
                    (t) => TagBadge(
                      tag: t,
                      onRemove: () {
                        _viewModel.removeFilterTag(t);
                      },
                    ),
                  ),
                  onAdd: () async {
                    final tags = await AddTagsDialog.show(
                      context,
                      alreadySelected: _viewModel.filterTags.toSet(),
                      enableTagEdits: false,
                      title: "Select tags",
                      addBtnText: "Select",
                    );
                    if (tags == null || tags.isEmpty) return;
                    _viewModel.addFilterTags(tags);
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: AlignmentGeometry.bottomRight,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
