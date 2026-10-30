/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart' hide ReactiveTextField;
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/add_field_row.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';
import 'package:sheetopia/ui/common/metadata_form_viewmodel.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/reactive_text_field.dart';
import 'package:sheetopia/ui/common/source_value.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';

class MetadataForm<T extends MetadataField> extends StatefulWidget {
  final MetadataFormViewModel<T> viewModel;
  final String titleControlName;
  final List<T> permanentFields;

  /// fields that should always show the label above the value input not next to it
  final Set<T> stackedFields;

  final Widget Function(T field, FocusNode focusNode) buildFieldWidget;

  /// returning false cancels the add
  final Future<void> Function(T field) onAdd;

  final String? Function(T field) removeMessage;
  final Widget? action;

  const MetadataForm({
    super.key,
    required this.viewModel,
    required this.titleControlName,
    required this.permanentFields,
    this.stackedFields = const {},
    required this.buildFieldWidget,
    required this.onAdd,
    required this.removeMessage,
    this.action,
  });

  @override
  State<MetadataForm<T>> createState() => _MetadataFormState<T>();
}

class _MetadataFormState<T extends MetadataField>
    extends State<MetadataForm<T>> {
  final _titleFocus = FocusNode();
  final Map<T, FocusNode> _focusNodes = {};

  MetadataFormViewModel<T> get _viewModel => widget.viewModel;

  @override
  void dispose() {
    _titleFocus.dispose();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _focusOf(T field) => _focusNodes.putIfAbsent(field, FocusNode.new);

  Future<void> _add(T field) async {
    await widget.onAdd(field);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _focusNodes[field];
      if (node?.context != null) node!.requestFocus();
    });
  }

  Future<void> _remove(T field) async {
    final message = _viewModel.isFilled(field)
        ? widget.removeMessage(field)
        : null;
    if (message != null) {
      final confirmation = await ConfirmationDialog.showCancel(
        context,
        message: message,
      );
      if (confirmation != true) return;
    }
    await _viewModel.removeField(field);
  }

  Widget _row(T field) {
    final optional = _viewModel.optionalFields.contains(field);
    return MetadataRow.field(
      field,
      stacked: widget.stackedFields.contains(field),
      onRemove: optional ? () => _remove(field) : null,
      child: widget.buildFieldWidget(field, _focusOf(field)),
    );
  }

  Widget _mainCard() {
    return MetadataCard(
      title: ReactiveTextField<String>(
        formControlName: widget.titleControlName,
        focusNode: _titleFocus,
        onTapOutside: (event) => _titleFocus.unfocus(),
        selectAllOnTap: true,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      children: [for (final field in widget.permanentFields) _row(field)],
    );
  }

  Widget _optionalCard() {
    return MetadataCard(
      children: [
        for (final field in _viewModel.optionalFields)
          if (_viewModel.isVisible(field)) _row(field),
        if (_viewModel.hiddenFields.isNotEmpty)
          AddFieldRow(fields: _viewModel.hiddenFields, onSelected: _add),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveForm(
      formGroup: _viewModel.form,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _mainCard(),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _optionalCard(),
                ),
              ],
            ),
          ),
          if (widget.action != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: widget.action,
              ),
            ),
        ],
      ),
    );
  }
}

class MetadataTagsValue extends StatelessWidget {
  final MetadataFormViewModel viewModel;
  final TagType type;

  const MetadataTagsValue({
    super.key,
    required this.viewModel,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return TagSelector(
      tags: viewModel.tags,
      type: type,
      onAdd: viewModel.addTags,
      onRemove: viewModel.removeTag,
      onSynced: viewModel.setTags,
    );
  }
}

class MetadataDifficultyValue extends StatelessWidget {
  final MetadataFormViewModel viewModel;

  const MetadataDifficultyValue({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return DifficultySelector(
      value: viewModel.difficulty,
      onChanged: viewModel.setDifficulty,
    );
  }
}

class MetadataSourceValue extends StatefulWidget {
  final MetadataFormViewModel viewModel;
  final FocusNode focusNode;
  final Future<Iterable<String>> Function(String filter) getOptions;

  const MetadataSourceValue({
    super.key,
    required this.viewModel,
    required this.focusNode,
    required this.getOptions,
  });

  @override
  State<MetadataSourceValue> createState() => _MetadataSourceValueState();
}

class _MetadataSourceValueState extends State<MetadataSourceValue> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return SourceValue(
      controller: _controller,
      link: viewModel.sourceLink,
      onLinkChanged: viewModel.setSourceLink,
      field: MetadataAutoCompleteField(
        form: viewModel.form,
        formControlName: MetadataFormViewModel.formSource,
        controller: _controller,
        focusNode: widget.focusNode,
        getOptions: widget.getOptions,
      ),
    );
  }
}

class MetadataTextValue extends StatelessWidget {
  final String formControlName;
  final FocusNode focusNode;
  final String hintText;

  const MetadataTextValue({
    super.key,
    required this.formControlName,
    required this.focusNode,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField<String>(
      formControlName: formControlName,
      focusNode: focusNode,
      onTapOutside: (event) => focusNode.unfocus(),
      maxLines: 8,
      minLines: 3,
      decoration: metadataInputDecoration(context, hintText: hintText),
    );
  }
}
