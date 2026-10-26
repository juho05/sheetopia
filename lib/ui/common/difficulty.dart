/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';

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

class DifficultySelector extends StatelessWidget {
  final Set<Difficulty?> selected;
  final List<Difficulty?> options;
  final void Function(Difficulty? difficulty) onPressed;
  final bool showLabel;

  DifficultySelector({
    super.key,
    required Difficulty? value,
    required void Function(Difficulty? difficulty) onChanged,
  }) : selected = {?value},
       options = Difficulty.values,
       onPressed = ((d) => onChanged(d == value ? null : d)),
       showLabel = true;

  DifficultySelector.multi({
    super.key,
    required Set<Difficulty?> values,
    required void Function(Difficulty? difficulty, bool selected) onToggle,
    bool includeNone = false,
  }) : selected = values,
       options = [if (includeNone) null, ...Difficulty.values],
       onPressed = ((d) => onToggle(d, !values.contains(d))),
       showLabel = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.bodyMedium!;
    return Row(
      spacing: 4,
      children: [
        for (final d in options)
          IconButton(
            icon: Icon(
              d == null ? Symbols.signal_cellular_off : difficultyIcon(d),
            ),
            iconSize: 22,
            isSelected: selected.contains(d),
            visualDensity: VisualDensity.compact,
            tooltip: d?.label ?? "No difficulty",
            color: muted.withAlpha(120),
            selectedIcon: Icon(
              d == null ? Symbols.signal_cellular_off : difficultyIcon(d),
              color: d == null ? muted : difficultyColor(context, d),
            ),
            style: IconButton.styleFrom(
              backgroundColor: selected.contains(d)
                  ? (d == null ? muted : difficultyColor(context, d)).withAlpha(
                      40,
                    )
                  : null,
            ),
            onPressed: () => onPressed(d),
          ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Flexible(
            child: selected.isEmpty
                ? Text(
                    "Not set",
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle.copyWith(color: muted),
                  )
                : DifficultyText(
                    difficulty: selected.single!,
                    style: labelStyle,
                  ),
          ),
        ],
      ],
    );
  }
}
