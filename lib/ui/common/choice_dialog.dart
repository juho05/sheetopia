/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class ChoiceOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final Widget? leading;

  const ChoiceOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leading,
  });
}

/// Renders one tile per option, without any dialog chrome, so the same
/// options can be embedded in a non-dialog surface (e.g. a blocking overlay).
List<Widget> buildChoiceTiles<T>(
  List<ChoiceOption<T>> options,
  void Function(T value) onSelected,
) {
  const optionHeight = 72.0;
  const optionHeightWithSubtitle = 96.0;
  return [
    for (final option in options)
      RoundedListTile(
        title: option.title,
        subtitle: option.subtitle == null ? null : Text(option.subtitle!),
        subtitleMaxLines: 2,
        tooltip: false,
        height: option.subtitle == null
            ? optionHeight
            : optionHeightWithSubtitle,
        leading: option.leading,
        onTap: () => onSelected(option.value),
      ),
  ];
}

class ChoiceDialog<T> extends StatelessWidget {
  final String title;
  final List<ChoiceOption<T>> options;

  const ChoiceDialog._({required this.title, required this.options});

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<ChoiceOption<T>> options,
  }) {
    return showSheetopiaDialog<T>(
      context: context,
      builder: (context) => ChoiceDialog<T>._(title: title, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          ...buildChoiceTiles(options, (value) {
            Navigator.pop(context, value);
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
