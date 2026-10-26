/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';

class AddFieldRow<T extends MetadataField> extends StatelessWidget {
  final String label;
  final Iterable<T> fields;
  final void Function(T field) onSelected;

  const AddFieldRow({
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
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return InkWell(
      onTap: () => _choose(context),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: SizedBox(
        height: 48,
        child: Row(
          spacing: 12,
          children: [
            Icon(Icons.add, size: 20, color: color),
            Text(
              label,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
