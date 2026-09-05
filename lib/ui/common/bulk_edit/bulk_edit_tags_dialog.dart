/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';

class BulkEditTagsResult {
  final Iterable<String> addIds;
  final Iterable<String> removeIds;

  BulkEditTagsResult({required this.addIds, required this.removeIds});
}

class BulkEditTagsDialog extends StatefulWidget {
  final TagType type;

  const BulkEditTagsDialog({super.key, this.type = TagType.score});

  static Future<BulkEditTagsResult?> show(
    BuildContext context, {
    TagType type = TagType.score,
  }) async {
    return showSheetopiaDialog<BulkEditTagsResult>(
      context: context,
      builder: (context) => BulkEditTagsDialog(type: type),
    );
  }

  @override
  State<BulkEditTagsDialog> createState() => _BulkEditTagsDialogState();
}

class _BulkEditTagsDialogState extends State<BulkEditTagsDialog> {
  final SplayTreeSet<Tag> _addTags = SplayTreeSet(
    (a, b) => a.name.compareTo(b.name),
  );
  final SplayTreeSet<Tag> _removeTags = SplayTreeSet(
    (a, b) => a.name.compareTo(b.name),
  );

  bool get _valid => _addTags.isNotEmpty || _removeTags.isNotEmpty;

  void _setTags(SplayTreeSet<Tag> target, Iterable<Tag> tags) {
    setState(() {
      target
        ..clear()
        ..addAll(tags);
    });
  }

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
                "Bulk edit tags",
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
            ],
          ),
          const Heading(text: "Add tags"),
          TagSelector(
            tags: _addTags,
            type: widget.type,
            dialogTitle: "Add tags",
            onAdd: (tags) {
              setState(() {
                _removeTags.removeAll(tags);
                _addTags.addAll(tags);
              });
            },
            onRemove: (t) {
              setState(() {
                _addTags.remove(t);
              });
            },
            onSynced: (tags) => _setTags(_addTags, tags),
          ),
          const SizedBox(height: 4),
          const Heading(text: "Remove tags"),
          TagSelector(
            tags: _removeTags,
            type: widget.type,
            dialogTitle: "Remove tags",
            onAdd: (tags) {
              setState(() {
                _addTags.removeAll(tags);
                _removeTags.addAll(tags);
              });
            },
            onRemove: (t) {
              setState(() {
                _removeTags.remove(t);
              });
            },
            onSynced: (tags) => _setTags(_removeTags, tags),
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
                          BulkEditTagsResult(
                            addIds: _addTags.map((t) => t.id),
                            removeIds: _removeTags.map((t) => t.id),
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
