/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/routing/router.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/select_tags_list.dart';
import 'package:sheetopia/ui/edit_score/source_input_dialog.dart';
import 'package:sheetopia/ui/practice/edit_exercise_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class EditExerciseForm extends StatefulWidget {
  const EditExerciseForm({super.key});

  @override
  State<EditExerciseForm> createState() => _EditExerciseFormState();
}

class _EditExerciseFormState extends State<EditExerciseForm> {
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _instrumentFocus = FocusNode();
  final _instrumentController = TextEditingController();

  @override
  void dispose() {
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _instrumentFocus.dispose();
    _instrumentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditExerciseViewModel>(
      builder: (context, viewModel, _) {
        return ReactiveForm(
          formGroup: viewModel.form,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    ReactiveTextField<String>(
                      formControlName: EditExerciseViewModel.formName,
                      focusNode: _titleFocus,
                      onTapOutside: (event) => _titleFocus.unfocus(),
                      decoration: const InputDecoration(
                        label: Text("Title"),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 4),
                      child: ReactiveTextField<String>(
                        formControlName: EditExerciseViewModel.formDescription,
                        focusNode: _descriptionFocus,
                        onTapOutside: (event) => _descriptionFocus.unfocus(),
                        maxLines: 8,
                        minLines: 3,
                        decoration: const InputDecoration(
                          label: Text("Description"),
                          border: OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AutoCompleteField(
                        controller: _instrumentController,
                        focusNode: _instrumentFocus,
                        getOptions: (filter) =>
                            viewModel.getInstruments(filter: filter),
                        onSelected: (option) =>
                            viewModel
                                    .form
                                    .controls[EditExerciseViewModel
                                        .formInstrument]!
                                    .value =
                                option,
                        fieldBuilder: (context, controller, focusNode) =>
                            ReactiveTextField(
                              onTapOutside: (event) => focusNode.unfocus(),
                              formControlName:
                                  EditExerciseViewModel.formInstrument,
                              controller: controller,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                label: Text("Instrument"),
                                border: OutlineInputBorder(),
                              ),
                            ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 4),
                      child: Heading(text: "Source"),
                    ),
                    _SourceRow(viewModel: viewModel),
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
                          type: TagType.exercise,
                          reloadTags: viewModel.reloadExercise,
                        );
                        if (tags == null || tags.isEmpty) return;
                        viewModel.addTags(tags);
                      },
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: viewModel.isCreate
                      ? _CreateButton(viewModel: viewModel)
                      : _DeleteButton(viewModel: viewModel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  final EditExerciseViewModel viewModel;

  const _CreateButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, _) => FilledButton(
        onPressed: form.valid
            ? () async {
                await viewModel.create();
                if (!context.mounted) return;
                context.pop();
              }
            : null,
        child: const Text("Create"),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final EditExerciseViewModel viewModel;

  const _DeleteButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: () async {
        final name = viewModel.name;
        final confirmation = await ConfirmationDialog.showYesNo(
          context,
          message: "Delete '$name'?",
        );
        if (confirmation != true) return;
        await viewModel.delete();
        Toast.show("Successfully deleted exercise '$name'!");
        goRouter.pop();
      },
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      icon: const Icon(Icons.delete_outline),
      label: const Text("Delete"),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final EditExerciseViewModel viewModel;

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
      message: "Remove the source from this exercise?",
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
            Tooltip(
              message: link,
              child: CommonBadge(
                name: source,
                color: theme.colorScheme.primaryContainer,
                foreground: theme.colorScheme.onPrimaryContainer,
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
