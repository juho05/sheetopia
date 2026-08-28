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
import 'package:sheetopia/ui/practice/manage_categories_dialog.dart';

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExercisesViewModel(repo: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Exercises")),
          body: SafeArea(
            child: _ExercisesList(
              viewModel: context.read<ExercisesViewModel>(),
            ),
          ),
          floatingActionButton: FabMenu(
            icon: const Icon(Symbols.edit),
            items: [
              FabMenuItem(
                label: "Create exercise",
                onPressed: () {
                  context.go("/practice/exercises/create");
                },
                icon: Symbols.add,
              ),
              FabMenuItem(
                label: "Manage categories",
                onPressed: () => ManageCategoriesDialog.show(context),
                icon: Symbols.category,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExercisesList extends StatefulWidget {
  final ExercisesViewModel viewModel;

  const _ExercisesList({required this.viewModel});

  @override
  State<_ExercisesList> createState() => _ExercisesListState();
}

class _ExercisesListState extends State<_ExercisesList> {
  late final ExercisesViewModel _viewModel = widget.viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadNextPage();
    Future.delayed(const Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted) return;
        _loadInitialPages().then(
          (_) => _scrollController.addListener(_checkEndReached),
        );
      });
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkEndReached);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPages() async {
    while (mounted && _isBottom && _viewModel.hasNextPage) {
      await _viewModel.loadNextPage();
    }
  }

  void _checkEndReached() {
    if (_isBottom) _viewModel.loadNextPage();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    if (!position.hasContentDimensions || !position.hasPixels) return false;
    return _scrollController.offset >=
        position.maxScrollExtent - 3 * RoundedListTile.defaultHeight;
  }

  Widget _buildCountLabel(BuildContext context) {
    final count = _viewModel.resultCount;
    if (count == null) return const SizedBox.shrink();
    final total = _viewModel.totalCount;
    if (total == 0) return const SizedBox.shrink();
    final label = _viewModel.isFiltered && total != null && total != count
        ? "$count of $total"
        : "$count ${count == 1 ? "exercise" : "exercises"}";
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final theme = Theme.of(context);
    if (_viewModel.isFiltered) {
      return Center(
        child: Text(
          "No matching exercises.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(
            "No exercises yet.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.go("/practice/exercises/create"),
            icon: const Icon(Symbols.add),
            label: const Text("Create exercise"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final groups = _viewModel.exercises;
        final headers = groups.isNotEmpty && groups.first.category != null;
        return LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: SearchInput(
                              label: "Search",
                              onSearch: (query) =>
                                  _viewModel.filterSearch = query,
                            ),
                          ),
                          FilterButton(
                            active: _viewModel.hasFilters,
                            collapsed:
                                constraints.maxWidth <
                                FilterButton.collapseWidth,
                            onPressed: () => ExercisesFilterDialog.show(
                              context,
                              viewModel: _viewModel,
                            ),
                          ),
                        ],
                      ),
                      _buildCountLabel(context),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildPlaceholder(context),
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
                      itemExtent: RoundedListTile.extentFor(subtitle: true),
                      itemCount: group.exercise.length,
                      itemBuilder: (context, index) =>
                          _ExerciseTile(exercise: group.exercise[index]),
                    ),
                  ],
                ),
              if (groups.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 88)),
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
        context.go("/practice/exercises/${exercise.id}");
      },
    );
  }
}
