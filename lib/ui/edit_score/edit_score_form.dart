import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/tag_list.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form_viewmodel.dart';

class EditScoreForm extends StatelessWidget {
  const EditScoreForm({super.key});

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
                    decoration: const InputDecoration(
                      label: Text("Title"),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Autocomplete(
                      optionsBuilder: (textEditingValue) =>
                          viewModel.getComposers(filter: textEditingValue.text),
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
                  TagList(
                    tags: viewModel.instruments.map(
                      (i) => (id: i, name: i, color: null),
                    ),
                    onRemove: (instrument) {
                      viewModel.removeInstrument(instrument);
                    },
                    onAdd: () async {
                      final instrument = await AutoCompleteInputDialog.show(
                        context,
                        title: "Add instrument",
                        inputLabel: "Instrument",
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
                  TagList(
                    tags: viewModel.genres.map(
                      (g) => (id: g, name: g, color: null),
                    ),
                    onRemove: (genre) {
                      viewModel.removeGenre(genre);
                    },
                    onAdd: () async {
                      final genre = await AutoCompleteInputDialog.show(
                        context,
                        title: "Add genre",
                        inputLabel: "Genre",
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
                  TagList(
                    tags: viewModel.tags.map(
                      (t) => (id: t.id, name: t.name, color: t.color),
                    ),
                    onRemove: (id) {
                      viewModel.removeTagId(id);
                    },
                    onAdd: () async {
                      final tags = await AddTagsDialog.show(
                        context,
                        viewModel.tags.toSet(),
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
