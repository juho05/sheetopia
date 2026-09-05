/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/edit_score/auto_complete_input_dialog.dart';
import 'package:sheetopia/ui/common/select_tags_list.dart';

typedef GetValueOptions =
    Future<Iterable<String>> Function(String filter, Iterable<String> exclude);

class BulkEditValuesResult {
  final Iterable<String> add;
  final Iterable<String> remove;

  BulkEditValuesResult({required this.add, required this.remove});
}

class BulkEditValuesDialog extends StatefulWidget {
  final String title;
  final String valuesLabel;
  final String inputLabel;
  final GetValueOptions getOptions;

  const BulkEditValuesDialog({
    super.key,
    required this.title,
    required this.valuesLabel,
    required this.inputLabel,
    required this.getOptions,
  });

  static Future<BulkEditValuesResult?> show(
    BuildContext context, {
    required String title,
    required String valuesLabel,
    required String inputLabel,
    required GetValueOptions getOptions,
  }) async {
    return showSheetopiaDialog<BulkEditValuesResult>(
      context: context,
      builder: (context) => BulkEditValuesDialog(
        title: title,
        valuesLabel: valuesLabel,
        inputLabel: inputLabel,
        getOptions: getOptions,
      ),
    );
  }

  @override
  State<BulkEditValuesDialog> createState() => _BulkEditValuesDialogState();
}

class _BulkEditValuesDialogState extends State<BulkEditValuesDialog> {
  final SplayTreeSet<String> _addValues = SplayTreeSet();
  final SplayTreeSet<String> _removeValues = SplayTreeSet();

  bool get _valid => _addValues.isNotEmpty || _removeValues.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          Heading(text: "Add ${widget.valuesLabel}"),
          SelectTagsList(
            tags: _addValues.map(
              (v) => CommonBadge(
                name: v,
                onRemove: () {
                  setState(() {
                    _addValues.remove(v);
                  });
                },
              ),
            ),
            onAdd: () async {
              final value = await AutoCompleteInputDialog.show(
                context,
                title: "Add ${widget.inputLabel.toLowerCase()}",
                inputLabel: widget.inputLabel,
                submitBtnText: "Select",
                getOptions: (filter) => widget.getOptions(filter, _addValues),
              );
              if (value == null) return;
              setState(() {
                _removeValues.remove(value);
                _addValues.add(value);
              });
            },
          ),
          const SizedBox(height: 4),
          Heading(text: "Remove ${widget.valuesLabel}"),
          SelectTagsList(
            tags: _removeValues.map(
              (v) => CommonBadge(
                name: v,
                onRemove: () {
                  setState(() {
                    _removeValues.remove(v);
                  });
                },
              ),
            ),
            onAdd: () async {
              final value = await AutoCompleteInputDialog.show(
                context,
                title: "Remove ${widget.inputLabel.toLowerCase()}",
                inputLabel: widget.inputLabel,
                submitBtnText: "Select",
                getOptions: (filter) =>
                    widget.getOptions(filter, _removeValues),
              );
              if (value == null) return;
              setState(() {
                _addValues.remove(value);
                _removeValues.add(value);
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: _valid
                    ? () {
                        Navigator.pop(
                          context,
                          BulkEditValuesResult(
                            add: _addValues,
                            remove: _removeValues,
                          ),
                        );
                      }
                    : null,
                child: const Text("Update"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
