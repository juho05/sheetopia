/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart' hide ReactiveTextField;
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/add_field_button.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/reactive_text_field.dart';
import 'package:sheetopia/ui/common/score_field.dart';
import 'package:sheetopia/ui/common/section_card.dart';
import 'package:sheetopia/ui/common/select_tags_list.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/nextdonedelete_button.dart';
import 'package:sheetopia/ui/edit_score/source_input_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class EditScoreForm extends StatefulWidget {
  const EditScoreForm({super.key});

  @override
  State<EditScoreForm> createState() => _EditScoreFormState();
}

class _EditScoreFormState extends State<EditScoreForm> {
  final _titleFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _composerFocus = FocusNode();
  final _composerController = TextEditingController();
  final _arrangerFocus = FocusNode();
  final _arrangerController = TextEditingController();

  @override
  void dispose() {
    _titleFocus.dispose();
    _notesFocus.dispose();
    _composerFocus.dispose();
    _composerController.dispose();
    _arrangerFocus.dispose();
    _arrangerController.dispose();
    super.dispose();
  }

  Future<void> _addField(
    EditScoreFormViewModel viewModel,
    ScoreField field,
  ) async {
    switch (field) {
      case ScoreField.arranger:
        viewModel.showField(field);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _arrangerFocus.requestFocus(),
        );
      case ScoreField.source:
        final result = await SourceInputDialog.show(
          context,
          title: "Add source",
          submitBtnText: "Save",
          getOptions: (filter) => viewModel.getSources(filter: filter),
        );
        if (result == null) return;
        viewModel.showField(field);
        await viewModel.setSource(result.source, result.sourceLink);
      case ScoreField.genres:
        if (await _addGenre(viewModel)) viewModel.showField(field);
      case ScoreField.notes:
        viewModel.showField(field);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _notesFocus.requestFocus(),
        );
      case ScoreField.difficulty ||
          ScoreField.composer ||
          ScoreField.instruments ||
          ScoreField.tags:
        viewModel.showField(field);
    }
  }

  Future<bool> _addGenre(EditScoreFormViewModel viewModel) async {
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

  Widget _mainCard(EditScoreFormViewModel viewModel) {
    return SectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            child: AutoCompleteField(
              controller: _composerController,
              focusNode: _composerFocus,
              getOptions: (filter) => viewModel.getComposers(filter: filter),
              onSelected: (option) =>
                  viewModel.form
                          .control(EditScoreFormViewModel.formComposer)
                          .value =
                      option,
              fieldBuilder: (context, controller, focusNode) =>
                  ReactiveTextField(
                    onTapOutside: (event) => focusNode.unfocus(),
                    formControlName: EditScoreFormViewModel.formComposer,
                    controller: controller,
                    focusNode: focusNode,
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
            child: Heading(text: "Tags"),
          ),
          TagSelector(
            tags: viewModel.tags,
            type: TagType.score,
            onAdd: viewModel.addTags,
            onRemove: viewModel.removeTag,
            onSynced: viewModel.setTags,
          ),
        ],
      ),
    );
  }

  Widget _fieldInput(EditScoreFormViewModel viewModel, ScoreField field) {
    switch (field) {
      case ScoreField.arranger:
        return AutoCompleteField(
          controller: _arrangerController,
          focusNode: _arrangerFocus,
          getOptions: (filter) => viewModel.getArrangers(filter: filter),
          onSelected: (option) =>
              viewModel.form
                      .control(EditScoreFormViewModel.formArranger)
                      .value =
                  option,
          fieldBuilder: (context, controller, focusNode) => ReactiveTextField(
            onTapOutside: (event) => focusNode.unfocus(),
            formControlName: EditScoreFormViewModel.formArranger,
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: "Name",
              border: OutlineInputBorder(),
            ),
          ),
        );
      case ScoreField.difficulty:
        return DifficultyDropdown(
          value: viewModel.difficulty,
          label: null,
          onChanged: viewModel.setDifficulty,
        );
      case ScoreField.source:
        return _SourceRow(viewModel: viewModel);
      case ScoreField.genres:
        return SelectTagsList(
          tags: viewModel.genres.map(
            (g) => CommonBadge(
              name: g,
              onRemove: () {
                viewModel.removeGenre(g);
              },
            ),
          ),
          onAdd: () => _addGenre(viewModel),
        );
      case ScoreField.notes:
        return ReactiveTextField<String>(
          formControlName: EditScoreFormViewModel.formNotes,
          focusNode: _notesFocus,
          onTapOutside: (event) => _notesFocus.unfocus(),
          maxLines: 8,
          minLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        );
      case ScoreField.composer || ScoreField.instruments || ScoreField.tags:
        return const SizedBox();
    }
  }

  Future<void> _removeField(
    EditScoreFormViewModel viewModel,
    ScoreField field,
  ) async {
    final message = switch (field) {
      ScoreField.arranger when viewModel.hasArranger =>
        "Remove the arranger from this score?",
      ScoreField.source when viewModel.source != null =>
        "Remove the source from this score?",
      ScoreField.difficulty when viewModel.difficulty != null =>
        "Remove the difficulty from this score?",
      ScoreField.genres when viewModel.genres.isNotEmpty =>
        "Remove all genres from this score?",
      ScoreField.notes when viewModel.hasNotes => "Delete the notes?",
      _ => null,
    };
    if (message != null) {
      final confirmation = await ConfirmationDialog.showCancel(
        context,
        message: message,
      );
      if (confirmation != true) return;
    }
    await viewModel.removeField(field);
  }

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
            return Column(
              children: [
                Expanded(
                  child: ReactiveForm(
                    formGroup: viewModel.form,
                    child: ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        _mainCard(viewModel),
                        for (final field in ScoreField.formOptional)
                          if (viewModel.isVisible(field))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SectionCard(
                                title: field.label,
                                padding: const EdgeInsets.all(12),
                                trailing: [
                                  RemoveFieldButton(
                                    onPressed: () =>
                                        _removeField(viewModel, field),
                                  ),
                                ],
                                child: _fieldInput(viewModel, field),
                              ),
                            ),
                        if (viewModel.hiddenFields.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: AddFieldButton(
                              fields: viewModel.hiddenFields,
                              onSelected: (field) =>
                                  _addField(viewModel, field),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Consumer<EditScoreViewModel>(
                      builder: (context, editScoreViewModel, _) =>
                          NextDoneDeleteButton(viewModel: editScoreViewModel),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SourceRow extends StatelessWidget {
  final EditScoreFormViewModel viewModel;

  const _SourceRow({required this.viewModel});

  void _openLink(String link) {
    try {
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } on FormatException catch (e, st) {
      Log.error("failed to open source link", e: e, st: st);
    }
  }

  Future<void> _edit(BuildContext context) async {
    final result = await SourceInputDialog.show(
      context,
      title: viewModel.source == null ? "Add source" : "Edit source",
      submitBtnText: "Save",
      source: viewModel.source ?? "",
      sourceLink: viewModel.sourceLink ?? "",
      getOptions: (filter) => viewModel.getSources(filter: filter),
    );
    if (result == null) return;
    viewModel.setSource(result.source, result.sourceLink);
  }

  Future<void> _remove(BuildContext context) async {
    final confirmation = await ConfirmationDialog.showCancel(
      context,
      message: "Remove the source from this score?",
    );
    if (confirmation != true) return;
    viewModel.setSource("", "");
  }

  @override
  Widget build(BuildContext context) {
    final source = viewModel.source;
    final link = viewModel.sourceLink;

    final theme = Theme.of(context);
    return SelectTagsList(
      tags: [
        if (source != null)
          if (link == null)
            CommonBadge(name: source, onRemove: () => _remove(context))
          else
            OptionalTooltip(
              message: link,
              child: CommonBadge(
                name: source,
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.primary,
                foreground: theme.brightness == Brightness.dark
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onPrimary,
                tooltip: false,
                trailingIcon: Symbols.open_in_new,
                onTap: () => _openLink(link),
                onRemove: () => _remove(context),
              ),
            ),
      ],
      addLabel: source == null ? "Set" : "Edit",
      addIcon: source == null ? Icons.add : Icons.edit,
      onAdd: () => _edit(context),
    );
  }
}
