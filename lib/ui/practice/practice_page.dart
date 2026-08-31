/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/section_header.dart';

typedef _Routine = ({String name, int exerciseCount, Duration duration});

class PracticePage extends StatelessWidget {
  static const double _fabPadding = 88;
  static const double _horizontalPadding = RoundedListTile.horizontalMargin;
  static const double _wideLayoutWidth = 560;

  static const List<_Routine> _routines = [
    (
      name: "Morning warm-up",
      exerciseCount: 4,
      duration: Duration(minutes: 20),
    ),
    (
      name: "Scales and arpeggios",
      exerciseCount: 7,
      duration: Duration(minutes: 35),
    ),
    (name: "Sight reading", exerciseCount: 3, duration: Duration(minutes: 15)),
  ];

  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutWidth;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                4,
                _horizontalPadding,
                8,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    _buildSummary(wide),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        const SectionHeader(text: "Routines"),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: SearchInput(
                                label: "Search routines",
                                onSearch: (query) {
                                  // TODO
                                },
                              ),
                            ),
                            FilterButton(
                              active: false,
                              collapsed:
                                  constraints.maxWidth <
                                  FilterButton.collapseWidth,
                              onPressed: () {
                                // TODO
                              },
                            ),
                          ],
                        ),
                        _buildCountLabel(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_routines.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildPlaceholder(context),
              )
            else
              SliverFixedExtentList.builder(
                itemExtent: RoundedListTile.extentFor(subtitle: true),
                itemCount: _routines.length,
                itemBuilder: (context, index) =>
                    _RoutineTile(routine: _routines[index]),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: _fabPadding)),
          ],
        );
      },
    );
  }

  Widget _buildSummary(bool wide) {
    const today = _TodayCard(practiced: Duration(hours: 1, minutes: 12));
    const exercises = _ExercisesCard();
    if (wide) {
      return const Row(
        spacing: 12,
        children: [
          Expanded(child: today),
          Expanded(child: exercises),
        ],
      );
    }
    return const Column(spacing: 12, children: [today, exercises]);
  }

  Widget _buildCountLabel(BuildContext context) {
    if (_routines.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      "${_routines.length} ${_routines.length == 1 ? "routine" : "routines"}",
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        "No routines yet.",
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  static const double height = 68;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  final Color color;
  final Widget child;
  final void Function()? onTap;

  const _SummaryCard({required this.color, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Duration practiced;

  const _TodayCard({required this.practiced});

  String get _label {
    final hours = practiced.inHours;
    final minutes = practiced.inMinutes.remainder(60);
    if (hours == 0) return "${minutes}min";
    return "${hours}h ${minutes}min";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SummaryCard(
      color: theme.colorScheme.primaryContainer,
      child: Row(
        spacing: 12,
        children: [
          RoundedTileIcon(
            icon: Symbols.timer,
            color: theme.colorScheme.primary,
            iconColor: theme.colorScheme.onPrimary,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  "Practiced today",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisesCard extends StatelessWidget {
  const _ExercisesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SummaryCard(
      color: theme.colorScheme.surfaceContainer,
      onTap: () => context.go("/practice/exercises"),
      child: Row(
        spacing: 12,
        children: [
          const RoundedTileIcon(icon: Symbols.exercise),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  "Exercises",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Browse and edit all exercises",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Symbols.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final _Routine routine;

  const _RoutineTile({required this.routine});

  String get _subtitle {
    final count = routine.exerciseCount;
    final minutes = routine.duration.inMinutes;
    return "$count ${count == 1 ? "exercise" : "exercises"} • ${minutes}min";
  }

  @override
  Widget build(BuildContext context) {
    return RoundedListTile(
      leading: const RoundedTileIcon(icon: Symbols.checklist),
      title: routine.name,
      subtitle: Text(_subtitle),
      onTap: () {
        // TODO
      },
      trailing: MenuButton(
        options: [
          ContextMenuOption(
            icon: Symbols.edit,
            title: "Rename",
            onSelected: null,
          ),
          ContextMenuOption(
            icon: Symbols.content_copy,
            title: "Duplicate",
            onSelected: null,
          ),
          ContextMenuOption(
            icon: Symbols.delete,
            title: "Delete",
            onSelected: null,
          ),
        ],
      ),
    );
  }
}
