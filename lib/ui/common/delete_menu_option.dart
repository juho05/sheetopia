/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';

class DeleteMenuOption extends ContextMenuOption {
  final String itemType;
  final String name;
  final Future<void> Function() onDelete;
  final Future<bool> Function(BuildContext context, String name)? confirm;

  DeleteMenuOption({
    required this.itemType,
    required this.name,
    required this.onDelete,
    this.confirm,
  }) : super(
         icon: Symbols.delete,
         title: "Delete",
         onSelected: (context) =>
             _delete(context, itemType, name, onDelete, confirm),
       );

  static Future<void> _delete(
    BuildContext context,
    String itemType,
    String name,
    Future<void> Function() onDelete,
    Future<bool> Function(BuildContext context, String name)? confirm,
  ) async {
    final confirmed = confirm != null
        ? await confirm(context, name)
        : await ConfirmationDialog.showYesNo(
                context,
                message: "Delete '$name'?",
              ) ==
              true;
    if (!confirmed) return;

    try {
      await onDelete();
    } catch (e, st) {
      Log.error("Failed to delete $itemType '$name'!", e: e, st: st);
      return;
    }

    Toast.show("Successfully deleted $itemType '$name'!");
    if (!context.mounted) return;
    context.pop();
  }
}
