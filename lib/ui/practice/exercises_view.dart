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
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/fab_menu.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/section_header.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/practice/exercises_filter_dialog.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';

class ExercisesView extends StatelessWidget {
  const ExercisesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExercisesViewModel(),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Exercises")),
          body: SafeArea(
            child: Consumer<ExercisesViewModel>(
              builder: (context, viewModel, _) {
                final groups = viewModel.exercises;
                final headers =
                    groups.isNotEmpty && groups.first.category != null;
                return LayoutBuilder(
                  builder: (context, constraints) => CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: SearchInput(
                                  label: "Search",
                                  onSearch: (query) =>
                                      viewModel.filterSearch = query,
                                ),
                              ),
                              FilterButton(
                                active: viewModel.hasFilters,
                                collapsed:
                                    constraints.maxWidth <
                                    FilterButton.collapseWidth,
                                onPressed: () => ExercisesFilterDialog.show(
                                  context,
                                  viewModel: viewModel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final group in groups)
                        SliverMainAxisGroup(
                          key: ValueKey(group.category),
                          slivers: [
                            if (headers)
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _CategoryHeaderDelegate(
                                  title: group.category ?? "No category",
                                ),
                              ),
                            SliverFixedExtentList.builder(
                              itemExtent: RoundedListTile.extentFor(
                                subtitle: true,
                              ),
                              itemCount: group.exercise.length,
                              itemBuilder: (context, index) => _ExerciseTile(
                                exercise: group.exercise[index],
                              ),
                            ),
                          ],
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FabMenu(
            icon: const Icon(Symbols.edit),
            items: [
              FabMenuItem(
                label: "Create exercise",
                onPressed: () {},
                icon: Symbols.add,
              ),
              FabMenuItem(
                label: "Manage categories",
                onPressed: () {},
                icon: Symbols.category,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const double height = 40;

  final String title;

  const _CategoryHeaderDelegate({required this.title});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: RoundedListTile.horizontalMargin + 16,
      ),
      child: SectionHeader(text: title),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) =>
      oldDelegate.title != title;
}

class _ExerciseTile extends StatelessWidget {
  static const double _badgeStripHeight = 22;

  final Exercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instrument = exercise.instrument;
    final hasBadges = instrument != null || exercise.tags.isNotEmpty;
    return RoundedListTile(
      height: RoundedListTile.defaultHeight,
      leading: const RoundedTileIcon(icon: Symbols.exercise),
      title: exercise.name,
      subtitle: !hasBadges
          ? null
          : SizedBox(
              height: _badgeStripHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 6,
                  children: [
                    if (instrument != null)
                      CommonBadge(
                        name: instrument,
                        tooltip: false,
                        compact: true,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    if (instrument != null && exercise.tags.isNotEmpty)
                      Container(
                        width: 1,
                        height: 14,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    for (final tag in exercise.tags)
                      TagBadge(tag: tag, tooltip: false, compact: true),
                  ],
                ),
              ),
            ),
      trailing: const MenuButton(options: []),
      onTap: () {
        // TODO
      },
    );
  }
}
