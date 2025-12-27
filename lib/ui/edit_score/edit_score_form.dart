import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/select_tags_list.dart';

class EditScoreForm extends StatefulWidget {
  const EditScoreForm({super.key});

  @override
  State<EditScoreForm> createState() => _EditScoreFormState();
}

class _EditScoreFormState extends State<EditScoreForm> {
  final _titleFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditScoreFormViewModel(
        editScoreViewModel: context.read(),
        scoresRepo: context.read(),
      ),
      builder: (context, _) {
        return Consumer<EditScoreFormViewModel>(
          builder: (context, viewModel, _) {
            return ReactiveForm(
              formGroup: viewModel.form,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ReactiveTextField<String>(
                    formControlName: EditScoreFormViewModel.formTitle,
                    focusNode: _titleFocus,
                    onTapOutside: (event) => _titleFocus.unfocus(),
                    decoration: const InputDecoration(
                      label: Text("Title"),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Autocomplete(
                      optionsBuilder: (textEditingValue) => viewModel
                          .getComposers(filter: textEditingValue.text.trim()),
                      onSelected: (option) =>
                          viewModel
                                  .form
                                  .controls[EditScoreFormViewModel
                                      .formComposer]!
                                  .value =
                              option,
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) => ReactiveTextField(
                            onTapOutside: (event) => focusNode.unfocus(),
                            formControlName:
                                EditScoreFormViewModel.formComposer,
                            controller: textEditingController,
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
                    tags: viewModel.instruments.map(
                      (i) => CommonBadge(
                        name: i,
                        onRemove: () {
                          viewModel.removeInstrument(i);
                        },
                      ),
                    ),
                    onAdd: () async {
                      final instrument = await AutoCompleteInputDialog.show(
                        context,
                        title: "Add instrument",
                        inputLabel: "Instrument",
                        submitBtnText: "Add",
                        getOptions: (filter) =>
                            viewModel.getInstruments(filter: filter),
                      );
                      if (instrument == null) return;
                      viewModel.addInstrument(instrument);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Heading(text: "Genres"),
                  ),
                  SelectTagsList(
                    tags: viewModel.genres.map(
                      (g) => CommonBadge(
                        name: g,
                        onRemove: () {
                          viewModel.removeGenre(g);
                        },
                      ),
                    ),
                    onAdd: () async {
                      final genre = await AutoCompleteInputDialog.show(
                        context,
                        title: "Add genre",
                        inputLabel: "Genre",
                        submitBtnText: "Add",
                        getOptions: (filter) =>
                            viewModel.getGenres(filter: filter),
                      );
                      if (genre == null) return;
                      viewModel.addGenre(genre);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Heading(text: "Tags"),
                  ),
                  SelectTagsList(
                    tags: viewModel.tags.map(
                      (t) => TagBadge(
                        tag: t,
                        onRemove: () {
                          viewModel.removeTag(t);
                        },
                      ),
                    ),
                    onAdd: () async {
                      final tags = await AddTagsDialog.show(
                        context,
                        alreadySelected: viewModel.tags.toSet(),
                        enableTagEdits: true,
                        reloadTags: viewModel.reloadScore,
                      );
                      if (tags == null || tags.isEmpty) return;
                      viewModel.addTags(tags);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
