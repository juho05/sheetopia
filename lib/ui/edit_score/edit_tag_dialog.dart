/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_color_picker/reactive_color_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/edit_score/edit_tag_viewmodel.dart';

class EditTagDialog extends StatefulWidget {
  final EditTagViewModel viewModel;

  const EditTagDialog({super.key, required this.viewModel});

  static Future<Tag?> showCreate(
    BuildContext context, {
    required TagType type,
    String? name,
  }) async {
    final viewModel = EditTagViewModel(
      repo: context.read(),
      type: type,
      initialName: name,
    );
    return await showSheetopiaDialog<Tag>(
      context: context,
      builder: (context) {
        return EditTagDialog(viewModel: viewModel);
      },
    );
  }

  static Future<bool> showEdit(
    BuildContext context,
    Tag tag, {
    required TagType type,
  }) async {
    final viewModel = EditTagViewModel(
      repo: context.read(),
      type: type,
      initialName: tag.name,
      initialColor: tag.color,
      tagId: tag.id,
    );
    return await showSheetopiaDialog<bool>(
          context: context,
          builder: (context) {
            return EditTagDialog(viewModel: viewModel);
          },
        ) ??
        false;
  }

  @override
  State<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends State<EditTagDialog> {
  final FocusNode _nameFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: ReactiveForm(
        formGroup: widget.viewModel.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              widget.viewModel.editMode ? "Edit tag" : "Create tag",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            ReactiveTextField(
              formControlName: EditTagViewModel.formName,
              focusNode: _nameFocus,
              onTapOutside: (event) => _nameFocus.unfocus(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Name",
              ),
            ),
            ReactiveColorPicker(
              formControlName: EditTagViewModel.formColor,
              enableAlpha: false,
              hexInputBar: false,
              displayThumbColor: true,
              decoration: const InputDecoration(border: InputBorder.none),
              colorPickerBuilder: (pickColor, color) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (color == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Color"),
                        onPressed: () => pickColor(),
                      ),
                    if (color != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text("Color"),
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                        onPressed: () => pickColor(),
                      ),
                  ],
                );
              },
              colorPickerDialogBuilder: (colorPicker) {
                return AlertDialog(
                  insetPadding: const EdgeInsets.all(8),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Select"),
                    ),
                  ],
                  titlePadding: const EdgeInsets.all(0.0),
                  contentPadding: const EdgeInsets.all(0.0),
                  content: SingleChildScrollView(child: colorPicker),
                );
              },
            ),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ReactiveFormConsumer(
                  builder: (context, form, _) {
                    return FilledButton(
                      onPressed: form.valid
                          ? () async {
                              if (widget.viewModel.editMode) {
                                await widget.viewModel.updateTag();
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } else {
                                final tag = await widget.viewModel.createTag();
                                if (context.mounted) {
                                  Navigator.pop(context, tag);
                                }
                              }
                            }
                          : null,
                      child: Text(
                        widget.viewModel.editMode ? "Update" : "Create",
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
