/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/ui/edit_score/select_tags_list.dart';

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

  StreamSubscription? _tagsChangedSub;

  @override
  void initState() {
    super.initState();

    final repo = context.read<ScoresRepository>();
    _tagsChangedSub = repo.updatedTagIds.listen((tagIds) async {
      Set<Tag> newAddTags = _addTags;
      Set<Tag> newRemoveTags = _removeTags;

      final addTagIds = _addTags.map((t) => t.id).toSet();
      if (tagIds.intersection(addTagIds).isNotEmpty) {
        newAddTags = (await repo.getTagsById(addTagIds)).toSet();
      }

      final removeTagIds = _removeTags.map((t) => t.id).toSet();
      if (tagIds.intersection(removeTagIds).isNotEmpty) {
        newRemoveTags = (await repo.getTagsById(removeTagIds)).toSet();
      }

      if (newAddTags == _addTags && newRemoveTags == _removeTags) return;
      setState(() {
        _addTags.clear();
        _addTags.addAll(newAddTags);
        _removeTags.clear();
        _removeTags.addAll(newRemoveTags);
      });
    });
  }

  @override
  void dispose() {
    _tagsChangedSub?.cancel();
    super.dispose();
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
          SelectTagsList(
            tags: _addTags.map(
              (t) => TagBadge(
                tag: t,
                onRemove: () {
                  setState(() {
                    _addTags.remove(t);
                  });
                },
              ),
            ),
            onAdd: () async {
              final tags = await AddTagsDialog.show(
                context,
                alreadySelected: _addTags,
                enableTagEdits: true,
                type: widget.type,
                title: "Add tags",
              );
              if (tags == null || tags.isEmpty) return;
              setState(() {
                _removeTags.removeAll(tags);
                _addTags.addAll(tags);
              });
            },
          ),
          const SizedBox(height: 4),
          const Heading(text: "Remove tags"),
          SelectTagsList(
            tags: _removeTags.map(
              (t) => TagBadge(
                tag: t,
                onRemove: () {
                  setState(() {
                    _removeTags.remove(t);
                  });
                },
              ),
            ),
            onAdd: () async {
              final tags = await AddTagsDialog.show(
                context,
                alreadySelected: _removeTags,
                enableTagEdits: true,
                type: widget.type,
                title: "Remove tags",
              );
              if (tags == null || tags.isEmpty) return;
              setState(() {
                _addTags.removeAll(tags);
                _removeTags.addAll(tags);
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
