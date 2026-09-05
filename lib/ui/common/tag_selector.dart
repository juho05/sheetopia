/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/ui/common/select_tags_list.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_dialog.dart';
import 'package:sheetopia/utils/tag_sync.dart';

class TagSelector extends StatefulWidget {
  final Iterable<Tag> tags;
  final TagType type;
  final bool enableCreateTagFromSearch;
  final String dialogTitle;
  final String addBtnText;
  final String addLabel;

  final void Function(List<Tag> tags) onAdd;
  final void Function(Tag tag) onRemove;

  // called when tags were edited or deleted elsewhere, the selection has to be
  // replaced with the given tags without touching the database
  final void Function(List<Tag> tags) onSynced;

  const TagSelector({
    super.key,
    required this.tags,
    required this.type,
    required this.onAdd,
    required this.onRemove,
    required this.onSynced,
    this.enableCreateTagFromSearch = true,
    this.dialogTitle = "Add tags",
    this.addBtnText = "Add",
    this.addLabel = "Add",
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  late final TagSync _sync;

  @override
  void initState() {
    super.initState();
    _sync = TagSync(
      repo: context.read(),
      currentTags: () => widget.tags,
      onChanged: (tags) {
        if (!mounted) return;
        widget.onSynced(tags);
      },
    );
    _sync.sync();
  }

  @override
  void dispose() {
    _sync.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final tags = await AddTagsDialog.show(
      context,
      alreadySelected: widget.tags.toSet(),
      enableCreateTagFromSearch: widget.enableCreateTagFromSearch,
      type: widget.type,
      title: widget.dialogTitle,
      addBtnText: widget.addBtnText,
    );
    if (tags == null || tags.isEmpty) return;
    widget.onAdd(tags);
  }

  @override
  Widget build(BuildContext context) {
    return SelectTagsList(
      tags: widget.tags.map(
        (t) => TagBadge(tag: t, onRemove: () => widget.onRemove(t)),
      ),
      addLabel: widget.addLabel,
      onAdd: _add,
    );
  }
}
