/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/musical_key.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';
import 'package:sheetopia/ui/common/musical_key.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/source_value.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';

typedef GetOptions =
    Future<Iterable<String>> Function(String filter, Iterable<String> exclude);

enum BulkInputKind {
  text,
  source,
  difficulty,
  musicalKey,
  valueList,
  tags,
  category,
}

class BulkMetadataField {
  final MetadataField field;
  final BulkInputKind kind;
  final GetOptions? getOptions;
  final TagType tagType;

  final String? valueLabel;

  const BulkMetadataField(
    this.field,
    this.kind, {
    this.getOptions,
    this.tagType = TagType.score,
    this.valueLabel,
  });
}

sealed class BulkMetadataEdit {
  MetadataField get field;
}

class BulkTextEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final String value;

  BulkTextEdit(this.field, this.value);
}

class BulkSourceEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final String source;
  final String sourceLink;

  BulkSourceEdit(this.field, this.source, this.sourceLink);
}

class BulkDifficultyEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final Difficulty? difficulty;

  BulkDifficultyEdit(this.field, this.difficulty);
}

class BulkMusicalKeyEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final MusicalKey? musicalKey;

  BulkMusicalKeyEdit(this.field, this.musicalKey);
}

class BulkValuesEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final Iterable<String> add;
  final Iterable<String> remove;

  BulkValuesEdit(this.field, {required this.add, required this.remove});
}

class BulkTagsEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final Iterable<String> addIds;
  final Iterable<String> removeIds;

  BulkTagsEdit(this.field, {required this.addIds, required this.removeIds});
}

class BulkCategoryEdit extends BulkMetadataEdit {
  @override
  final MetadataField field;
  final ExerciseCategory? category;

  BulkCategoryEdit(this.field, this.category);
}

class BulkEditMetadataDialog extends StatefulWidget {
  final String title;
  final List<BulkMetadataField> fields;

  const BulkEditMetadataDialog._({required this.title, required this.fields});

  static Future<BulkMetadataEdit?> show(
    BuildContext context, {
    required String title,
    required List<BulkMetadataField> fields,
  }) {
    return showSheetopiaDialog<BulkMetadataEdit>(
      context: context,
      builder: (context) =>
          BulkEditMetadataDialog._(title: title, fields: fields),
    );
  }

  @override
  State<BulkEditMetadataDialog> createState() => _BulkEditMetadataDialogState();
}

class _BulkEditMetadataDialogState extends State<BulkEditMetadataDialog> {
  BulkMetadataField? _field;

  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  String _link = "";
  Difficulty? _difficulty;
  MusicalKey? _musicalKey;
  bool _categoryChosen = false;
  ExerciseCategory? _category;
  final SplayTreeSet<String> _addValues = SplayTreeSet();
  final SplayTreeSet<String> _removeValues = SplayTreeSet();
  final SplayTreeSet<Tag> _addTags = SplayTreeSet(_byName);
  final SplayTreeSet<Tag> _removeTags = SplayTreeSet(_byName);

  static int _byName(Tag a, Tag b) => a.name.compareTo(b.name);

  String get _text => _textController.text.trim();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _selectField(BulkMetadataField? field) {
    if (field == null || field == _field) return;
    setState(() {
      _field = field;
      _textController.clear();
      _link = "";
      _difficulty = null;
      _musicalKey = null;
      _categoryChosen = false;
      _category = null;
      _addValues.clear();
      _removeValues.clear();
      _addTags.clear();
      _removeTags.clear();
    });
    if (field.kind == BulkInputKind.text ||
        field.kind == BulkInputKind.source) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _textFocus.requestFocus(),
      );
    }
  }

  BulkMetadataEdit? get _result {
    final field = _field;
    if (field == null) return null;
    return switch (field.kind) {
      BulkInputKind.text => BulkTextEdit(field.field, _text),
      BulkInputKind.source => BulkSourceEdit(
        field.field,
        _text,
        _text.isEmpty ? "" : _link,
      ),
      BulkInputKind.difficulty => BulkDifficultyEdit(field.field, _difficulty),
      BulkInputKind.musicalKey => BulkMusicalKeyEdit(field.field, _musicalKey),
      BulkInputKind.valueList =>
        _addValues.isEmpty && _removeValues.isEmpty
            ? null
            : BulkValuesEdit(
                field.field,
                add: _addValues,
                remove: _removeValues,
              ),
      BulkInputKind.tags =>
        _addTags.isEmpty && _removeTags.isEmpty
            ? null
            : BulkTagsEdit(
                field.field,
                addIds: _addTags.map((t) => t.id).toList(),
                removeIds: _removeTags.map((t) => t.id).toList(),
              ),
      BulkInputKind.category =>
        _categoryChosen ? BulkCategoryEdit(field.field, _category) : null,
    };
  }

  bool get _clears => switch (_result) {
    BulkTextEdit(:final value) => value.isEmpty,
    BulkSourceEdit(:final source) => source.isEmpty,
    BulkDifficultyEdit(:final difficulty) => difficulty == null,
    BulkMusicalKeyEdit(:final musicalKey) => musicalKey == null,
    BulkCategoryEdit(:final category) => category == null,
    _ => false,
  };

  void _submit() {
    final result = _result;
    if (result == null) return;
    Navigator.pop(context, result);
  }

  void _submitUnlessClearing() {
    if (!_clears) _submit();
  }

  Future<void> _pickValue(
    // the set to add the picked value to
    SplayTreeSet<String> into,
    // the set to remove the picked value from if it is in it
    SplayTreeSet<String> other,
  ) async {
    final field = _field!;
    final label = field.valueLabel ?? field.field.label;
    final value = await AutoCompleteInputDialog.show(
      context,
      title: "Select ${label.toLowerCase()}",
      inputLabel: label,
      submitBtnText: "Select",
      getOptions: (filter) =>
          field.getOptions?.call(filter, into) ?? Future.value(const []),
    );
    if (value == null) return;
    setState(() {
      other.remove(value);
      into.add(value);
    });
  }

  Widget _tagSelector(
    BulkMetadataField field,
    SplayTreeSet<Tag> into,
    SplayTreeSet<Tag> other,
    String title,
  ) {
    return TagSelector(
      tags: into,
      type: field.tagType,
      dialogTitle: title,
      onAdd: (tags) => setState(() {
        other.removeAll(tags);
        into.addAll(tags);
      }),
      onRemove: (t) => setState(() => into.remove(t)),
      onSynced: (tags) => setState(() {
        into
          ..clear()
          ..addAll(tags);
      }),
    );
  }

  Widget _valueChips(
    SplayTreeSet<String> values,
    SplayTreeSet<String> other,
    String addTooltip,
  ) {
    return MetadataChips(
      chips: values.map(
        (v) => CommonBadge(
          name: v,
          onRemove: () => setState(() => values.remove(v)),
        ),
      ),
      addTooltip: addTooltip,
      onAdd: () => _pickValue(values, other),
    );
  }

  List<Widget> _input() {
    final field = _field;
    if (field == null) return const [];
    final label = field.field.label;
    switch (field.kind) {
      case BulkInputKind.text:
        return [_textField(field, label)];
      case BulkInputKind.source:
        return [
          SourceValue(
            controller: _textController,
            link: _link.isEmpty ? null : _link,
            onLinkChanged: (link) => setState(() => _link = link),
            field: _textField(field, label),
          ),
        ];
      case BulkInputKind.difficulty:
        return [
          DifficultySelector(
            value: _difficulty,
            onChanged: (value) => setState(() => _difficulty = value),
          ),
        ];
      case BulkInputKind.musicalKey:
        return [
          MusicalKeySelector(
            value: _musicalKey,
            onChanged: (value) => setState(() => _musicalKey = value),
          ),
        ];
      case BulkInputKind.category:
        return [
          CategorySelector(
            category: _category,
            emptyLabel: "No category",
            hint: _categoryChosen ? null : "Select a category",
            allowCreate: true,
            inline: true,
            onChanged: (category) => setState(() {
              _categoryChosen = true;
              _category = category;
            }),
          ),
        ];
      case BulkInputKind.valueList:
        final lower = label.toLowerCase();
        return [
          MetadataRow(
            icon: Icons.add,
            label: "Add",
            child: _valueChips(_addValues, _removeValues, "Add $lower"),
          ),
          MetadataRow(
            icon: Icons.remove,
            label: "Remove",
            child: _valueChips(_removeValues, _addValues, "Remove $lower"),
          ),
        ];
      case BulkInputKind.tags:
        return [
          MetadataRow(
            icon: Icons.add,
            label: "Add",
            child: _tagSelector(field, _addTags, _removeTags, "Add tags"),
          ),
          MetadataRow(
            icon: Icons.remove,
            label: "Remove",
            child: _tagSelector(field, _removeTags, _addTags, "Remove tags"),
          ),
        ];
    }
  }

  Widget _textField(BulkMetadataField field, String label) {
    return AutoCompleteField(
      key: ValueKey(field),
      controller: _textController,
      focusNode: _textFocus,
      getOptions: (filter) =>
          field.getOptions?.call(filter, const []) ?? Future.value(const []),
      onSubmitted: (_) => _submitUnlessClearing(),
      decoration: metadataInputDecoration(context, hintText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            DropdownMenu<BulkMetadataField>(
              initialSelection: _field,
              onSelected: _selectField,
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              enableSearch: false,
              label: const Text("Field"),
              leadingIcon: _field == null ? null : Icon(_field!.field.icon),
              dropdownMenuEntries: [
                for (final field in widget.fields)
                  DropdownMenuEntry(
                    value: field,
                    label: field.field.label,
                    leadingIcon: Icon(field.field.icon),
                  ),
              ],
            ),
            ..._input(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                if (_clears)
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text("Clear"),
                  )
                else
                  FilledButton(
                    onPressed: _result == null ? null : _submit,
                    child: const Text("Update"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
