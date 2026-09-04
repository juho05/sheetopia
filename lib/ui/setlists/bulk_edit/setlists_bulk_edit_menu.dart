/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';

class SetlistsBulkEditMenu extends StatefulWidget {
  final List<String> selectedSetlistIds;
  final void Function()? onDeleted;

  const SetlistsBulkEditMenu({
    super.key,
    required this.selectedSetlistIds,
    this.onDeleted,
  });

  @override
  State<SetlistsBulkEditMenu> createState() => _SetlistsBulkEditMenuState();
}

class _SetlistsBulkEditMenuState extends State<SetlistsBulkEditMenu> {
  late final SetlistsRepository _repo = context.read();

  Future<void> _delete() async {
    final count = widget.selectedSetlistIds.length;
    final setlists = count == 1 ? "setlist" : "setlists";
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete $count $setlists?",
      message:
          "They will be deleted on all your devices. "
          "The scores in them are not deleted.",
    );
    if (!confirmed) return;
    await _repo.deleteSetlists(widget.selectedSetlistIds.toSet());
    widget.onDeleted?.call();
    Toast.show("Deleted $count $setlists");
  }

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Delete",
          icon: Symbols.delete,
          onSelected: _delete,
        ),
      ],
    );
  }
}
