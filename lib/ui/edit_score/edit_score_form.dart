/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/metadata_form.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/musical_key.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/next_done_button.dart';

class EditScoreForm extends StatelessWidget {
  const EditScoreForm({super.key});

  Future<void> _addField(
    BuildContext context,
    EditScoreFormViewModel viewModel,
    ScoreField field,
  ) async {
    if (field == ScoreField.genres && !await _addGenre(context, viewModel)) {
      return;
    }
    viewModel.showField(field);
  }

  Future<bool> _addGenre(
    BuildContext context,
    EditScoreFormViewModel viewModel,
  ) async {
    final genre = await AutoCompleteInputDialog.show(
      context,
      title: "Add genre",
      inputLabel: "Genre",
      submitBtnText: "Add",
      getOptions: (filter) => viewModel.getGenres(filter: filter),
    );
    if (genre == null) return false;
    await viewModel.addGenre(genre);
    return true;
  }

  Future<void> _addInstrument(
    BuildContext context,
    EditScoreFormViewModel viewModel,
  ) async {
    final instrument = await AutoCompleteInputDialog.show(
      context,
      title: "Add instrument",
      inputLabel: "Instrument",
      submitBtnText: "Add",
      getOptions: (filter) => viewModel.getInstruments(filter: filter),
    );
    if (instrument == null) return;
    viewModel.addInstrument(instrument);
  }

  Widget _fieldWidget(
    BuildContext context,
    EditScoreFormViewModel viewModel,
    ScoreField field,
    FocusNode focusNode,
  ) {
    switch (field) {
      case ScoreField.composer:
        return MetadataAutoCompleteField(
          form: viewModel.form,
          formControlName: EditScoreFormViewModel.formComposer,
          focusNode: focusNode,
          getOptions: viewModel.composerOptions.get,
        );
      case ScoreField.arranger:
        return MetadataAutoCompleteField(
          form: viewModel.form,
          formControlName: EditScoreFormViewModel.formArranger,
          focusNode: focusNode,
          getOptions: viewModel.arrangerOptions.get,
        );
      case ScoreField.partOf:
        return MetadataAutoCompleteField(
          form: viewModel.form,
          formControlName: EditScoreFormViewModel.formPartOf,
          focusNode: focusNode,
          getOptions: viewModel.partOfOptions.get,
        );
      case ScoreField.musicalKey:
        return MusicalKeySelector(
          value: viewModel.musicalKey,
          onChanged: viewModel.setMusicalKey,
        );
      case ScoreField.instruments:
        return MetadataChips(
          chips: viewModel.instruments.map(
            (i) => CommonBadge(
              name: i,
              onRemove: () => viewModel.removeInstrument(i),
            ),
          ),
          addTooltip: "Add instrument",
          onAdd: () => _addInstrument(context, viewModel),
        );
      case ScoreField.tags:
        return MetadataTagsValue(viewModel: viewModel, type: TagType.score);
      case ScoreField.difficulty:
        return MetadataDifficultyValue(viewModel: viewModel);
      case ScoreField.source:
        return MetadataSourceValue(
          viewModel: viewModel,
          focusNode: focusNode,
          getOptions: viewModel.sourceOptions.get,
        );
      case ScoreField.genres:
        return MetadataChips(
          chips: viewModel.genres.map(
            (g) =>
                CommonBadge(name: g, onRemove: () => viewModel.removeGenre(g)),
          ),
          addTooltip: "Add genre",
          onAdd: () => _addGenre(context, viewModel),
        );
      case ScoreField.notes:
        return MetadataTextValue(
          formControlName: EditScoreFormViewModel.formNotes,
          focusNode: focusNode,
          hintText: "No notes",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditScoreFormViewModel(
        editScoreViewModel: context.read(),
        scoresRepo: context.read(),
      ),
      builder: (context, _) {
        return Consumer2<EditScoreFormViewModel, EditScoreViewModel>(
          builder: (context, viewModel, editScoreViewModel, _) {
            return MetadataForm<ScoreField>(
              viewModel: viewModel,
              titleControlName: EditScoreFormViewModel.formTitle,
              permanentFields: const [
                ScoreField.composer,
                ScoreField.instruments,
                ScoreField.tags,
              ],
              stackedFields: const {ScoreField.notes},
              buildFieldWidget: (field, focusNode) =>
                  _fieldWidget(context, viewModel, field, focusNode),
              onAdd: (field) => _addField(context, viewModel, field),
              removeMessage: (field) => switch (field) {
                ScoreField.genres => "Remove all genres from this score?",
                ScoreField.notes => "Delete the notes?",
                ScoreField.partOf => 'Remove "Part of" from this score?',
                _ => "Remove the ${field.label.toLowerCase()} from this score?",
              },
              action: editScoreViewModel.isImport
                  ? NextDoneButton(viewModel: editScoreViewModel)
                  : null,
            );
          },
        );
      },
    );
  }
}
