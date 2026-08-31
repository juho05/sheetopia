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
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/section_header.dart';
import 'package:sheetopia/ui/common/selection/selectable_tile_icon.dart';
import 'package:sheetopia/ui/common/selection/selection_gestures.dart';
import 'package:sheetopia/ui/common/selection/selection_shortcuts.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/practice/exercises_filter_dialog.dart';
import 'package:sheetopia/ui/practice/exercises_viewmodel.dart';

class ExercisesView extends StatefulWidget {
  final ExercisesViewModel viewModel;

  final bool selectionMode;
  final void Function(Exercise exercise)? onExerciseSelected;
  final void Function(Exercise exercise)? onExerciseDeselected;
  final void Function(List<String> exerciseIds)? onExercisesSelected;
  final void Function()? onClearSelection;
  final Set<String> selected;

  final Widget? emptyAction;
  final double bottomPadding;

  const ExercisesView({
    super.key,
    required this.viewModel,
    this.selectionMode = false,
    this.onExerciseSelected,
    this.onExerciseDeselected,
    this.onExercisesSelected,
    this.onClearSelection,
    this.selected = const {},
    this.emptyAction,
    this.bottomPadding = 0,
  });

  @override
  State<ExercisesView> createState() => _ExercisesViewState();
}

class _ExercisesViewState extends State<ExercisesView> {
  late final ExercisesViewModel _viewModel = widget.viewModel;

  final ScrollController _scrollController = ScrollController();
  final RangeSelectionAnchor _rangeAnchor = RangeSelectionAnchor();

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
  void didUpdateWidget(ExercisesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectionMode) _rangeAnchor.clear();
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

  Future<void> _selectAll() async {
    final onExercisesSelected = widget.onExercisesSelected;
    if (onExercisesSelected == null) return;
    final exerciseIds = await _viewModel.getFilteredExerciseIds();
    if (!mounted) return;
    onExercisesSelected(exerciseIds);
  }

  void _selectExercise(Exercise exercise) {
    _rangeAnchor.anchor = exercise.id;
    widget.onExerciseSelected?.call(exercise);
  }

  void _deselectExercise(Exercise exercise) {
    _rangeAnchor.anchor = exercise.id;
    widget.onExerciseDeselected?.call(exercise);
  }

  void _toggleExercise(Exercise exercise) {
    if (widget.selected.contains(exercise.id)) {
      _deselectExercise(exercise);
    } else {
      _selectExercise(exercise);
    }
  }

  void _selectRangeTo(Exercise exercise) {
    final range = _rangeAnchor.rangeTo(
      _viewModel.loadedExerciseIds,
      exercise.id,
    );
    if (range == null) {
      _selectExercise(exercise);
      return;
    }
    widget.onExercisesSelected?.call(range);
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
          ?widget.emptyAction,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionShortcuts(
      onSelectAll: widget.onExercisesSelected != null ? _selectAll : null,
      onClearSelection: widget.selectionMode ? widget.onClearSelection : null,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _buildList(context),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
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
                          onSearch: (query) => _viewModel.filterSearch = query,
                        ),
                      ),
                      FilterButton(
                        active: _viewModel.hasFilters,
                        collapsed:
                            constraints.maxWidth < FilterButton.collapseWidth,
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
              key: ValueKey(group.category?.id),
              slivers: [
                if (headers)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryHeaderDelegate(
                      title: group.category?.name ?? "No category",
                    ),
                  ),
                SliverFixedExtentList.builder(
                  itemExtent: RoundedListTile.extentFor(subtitle: true),
                  itemCount: group.exercise.length,
                  itemBuilder: (context, index) {
                    final exercise = group.exercise[index];
                    return _ExerciseTile(
                      exercise: exercise,
                      selecting: widget.selectionMode,
                      selected: widget.selected.contains(exercise.id),
                      onToggle: _toggleExercise,
                      onSelectionStart: widget.onExerciseSelected != null
                          ? _selectExercise
                          : null,
                      onRangeSelect:
                          widget.onExerciseSelected != null &&
                              widget.onExercisesSelected != null
                          ? _selectRangeTo
                          : null,
                    );
                  },
                ),
              ],
            ),
          if (groups.isNotEmpty)
            SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
        ],
      ),
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
  final bool selecting;
  final bool selected;
  final void Function(Exercise exercise) onToggle;
  final void Function(Exercise exercise)? onSelectionStart;
  final void Function(Exercise exercise)? onRangeSelect;

  const _ExerciseTile({
    required this.exercise,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    this.onSelectionStart,
    this.onRangeSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instrument = exercise.instrument;
    final hasBadges = instrument != null || exercise.tags.isNotEmpty;
    final gestures = SelectionGestures(
      item: exercise,
      selecting: selecting,
      onToggle: onToggle,
      onSelectionStart: onSelectionStart,
      onRangeSelect: onRangeSelect,
      onActivate: () => context.go("/practice/exercises/${exercise.id}"),
    );
    return RoundedListTile(
      height: RoundedListTile.defaultHeight,
      leading: SelectableTileIcon(
        icon: Symbols.exercise,
        selecting: selecting,
        selected: selected,
      ),
      title: exercise.name,
      selected: selected,
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
      trailing: selecting ? null : const MenuButton(options: []),
      onTap: gestures.onTap,
      onLongPress: gestures.onLongPress,
    );
  }
}
