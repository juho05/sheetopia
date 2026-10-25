/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';
import 'package:sheetopia/ui/common/dashed_placeholder.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';

class AddFieldButton<T extends MetadataField> extends StatelessWidget {
  final String label;
  final Iterable<T> fields;
  final void Function(T field) onSelected;

  const AddFieldButton({
    super.key,
    this.label = "Add field",
    required this.fields,
    required this.onSelected,
  });

  Future<void> _choose(BuildContext context) async {
    final field = await ChoiceDialog.show<T>(
      context,
      title: label,
      options: [
        for (final field in fields)
          ChoiceOption(
            value: field,
            title: field.label,
            leading: RoundedTileIcon(icon: field.icon),
          ),
      ],
    );
    if (field != null) onSelected(field);
  }

  @override
  Widget build(BuildContext context) {
    return DashedPlaceholder(
      padding: const EdgeInsets.all(12),
      child: Button(
        onPressed: () => _choose(context),
        icon: Icons.add,
        darkTonal: true,
        child: Text(label),
      ),
    );
  }
}

class RemoveFieldButton extends StatelessWidget {
  final void Function() onPressed;

  const RemoveFieldButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      iconSize: 20,
      tooltip: "Remove field",
      onPressed: onPressed,
    );
  }
}
