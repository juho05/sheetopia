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
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';

class RoutinesBulkEditMenu extends StatefulWidget {
  final List<String> selectedRoutineIds;
  final void Function()? onDeleted;

  const RoutinesBulkEditMenu({
    super.key,
    required this.selectedRoutineIds,
    this.onDeleted,
  });

  @override
  State<RoutinesBulkEditMenu> createState() => _RoutinesBulkEditMenuState();
}

class _RoutinesBulkEditMenuState extends State<RoutinesBulkEditMenu> {
  late final PracticeRepository _repo = context.read();

  Future<void> _duplicate() async {
    final copies = await _repo.duplicateRoutines(widget.selectedRoutineIds);
    final count = copies.length;
    Toast.show("Duplicated $count ${count == 1 ? "routine" : "routines"}");
  }

  Future<void> _delete() async {
    final count = widget.selectedRoutineIds.length;
    final routines = count == 1 ? "routine" : "routines";
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete $count $routines?",
      message:
          "They will be deleted on all your devices. "
          "The exercises in them are not deleted.",
    );
    if (!confirmed) return;
    await _repo.deleteRoutines(widget.selectedRoutineIds.toSet());
    widget.onDeleted?.call();
    Toast.show("Deleted $count $routines");
  }

  @override
  Widget build(BuildContext context) {
    return MenuButton(
      options: [
        ContextMenuOption(
          title: "Duplicate",
          icon: Symbols.content_copy,
          onSelected: _duplicate,
        ),
        ContextMenuOption(
          title: "Delete",
          icon: Symbols.delete,
          onSelected: _delete,
        ),
      ],
    );
  }
}
