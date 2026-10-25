/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';
import 'package:sheetopia/ui/common/common_badge.dart';

Color difficultyColor(BuildContext context, Difficulty difficulty) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (difficulty) {
    Difficulty.veryEasy => dark ? Colors.green.shade400 : Colors.green.shade800,
    Difficulty.easy => dark ? Colors.lightGreen.shade300 : Colors.lime.shade900,
    Difficulty.medium => dark ? Colors.blue.shade300 : Colors.blue.shade700,
    Difficulty.hard => dark ? Colors.red.shade200 : Colors.red.shade700,
    Difficulty.veryHard => dark ? Colors.red.shade400 : const Color(0xFF8E0000),
  };
}

IconData difficultyIcon(Difficulty difficulty) => switch (difficulty) {
  Difficulty.veryEasy => Symbols.signal_cellular_0_bar,
  Difficulty.easy => Symbols.signal_cellular_1_bar,
  Difficulty.medium => Symbols.signal_cellular_2_bar,
  Difficulty.hard => Symbols.signal_cellular_3_bar,
  Difficulty.veryHard => Symbols.signal_cellular_4_bar,
};

class DifficultyIcon extends StatelessWidget {
  final Difficulty difficulty;
  final double size;
  final bool tooltip;

  const DifficultyIcon({
    super.key,
    required this.difficulty,
    this.size = 18,
    this.tooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      difficultyIcon(difficulty),
      size: size,
      color: difficultyColor(context, difficulty),
    );
    if (!tooltip) return icon;
    return Tooltip(message: difficulty.label, child: icon);
  }
}

class DifficultyText extends StatelessWidget {
  final Difficulty difficulty;
  final TextStyle? style;

  const DifficultyText({super.key, required this.difficulty, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      difficulty.label,
      overflow: TextOverflow.ellipsis,
      style: (style ?? const TextStyle()).copyWith(
        color: difficultyColor(context, difficulty),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class DifficultyBadge extends StatelessWidget {
  final Difficulty difficulty;
  final void Function()? onRemove;

  const DifficultyBadge({super.key, required this.difficulty, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(context, difficulty);
    return CommonBadge(
      name: difficulty.label,
      color: color,
      foreground: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      trailingIcon: difficultyIcon(difficulty),
      tooltip: false,
      onRemove: onRemove,
    );
  }
}

class DifficultyDropdown extends StatelessWidget {
  final Difficulty? value;
  final void Function(Difficulty? difficulty) onChanged;
  final String? label;

  const DifficultyDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = "Difficulty",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownMenu<Difficulty?>(
      // the menu keeps its own selection, rebuild it when the value changes
      key: ValueKey(value),
      initialSelection: value,
      onSelected: onChanged,
      expandedInsets: EdgeInsets.zero,
      requestFocusOnTap: false,
      enableSearch: false,
      label: label == null ? null : Text(label!),
      hintText: "Not set",
      leadingIcon: value == null
          ? null
          : Icon(
              difficultyIcon(value!),
              color: difficultyColor(context, value!),
            ),
      textStyle: value == null
          ? null
          : theme.textTheme.bodyLarge!.copyWith(
              color: difficultyColor(context, value!),
              fontWeight: FontWeight.w500,
            ),
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: null,
          label: "Not set",
          leadingIcon: const SizedBox.square(dimension: 24),
          labelWidget: Text(
            "Not set",
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        for (final d in Difficulty.values)
          DropdownMenuEntry(
            value: d,
            label: d.label,
            leadingIcon: DifficultyIcon(
              difficulty: d,
              size: 24,
              tooltip: false,
            ),
            labelWidget: DifficultyText(difficulty: d),
          ),
      ],
    );
  }
}

Future<Difficulty?> showDifficultyPicker(
  BuildContext context, {
  required String title,
  Iterable<Difficulty> exclude = const [],
}) {
  return ChoiceDialog.show<Difficulty>(
    context,
    title: title,
    options: [
      for (final d in Difficulty.values)
        if (!exclude.contains(d))
          ChoiceOption(
            value: d,
            title: d.label,
            leading: DifficultyIcon(difficulty: d, size: 24, tooltip: false),
          ),
    ],
  );
}
