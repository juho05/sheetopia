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
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/section_header.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';
import 'package:sheetopia/ui/practice/routines_filter_dialog.dart';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return "${minutes}min";
  return "${hours}h ${minutes}min";
}

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  static const double _fabPadding = 88;
  static const double _horizontalPadding = RoundedListTile.horizontalMargin;
  static const double _wideLayoutWidth = 560;

  late final PracticeRoutinesViewModel _viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeRoutinesViewModel(repo: context.read());
    _viewModel.loadNextPage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialPages().then(
        (_) => _scrollController.addListener(_checkEndReached),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkEndReached);
    _scrollController.dispose();
    _viewModel.dispose();
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _buildContent(context, constraints),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final routines = _viewModel.routines;
    return CustomScrollView(
      controller: _scrollController,
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
                _buildSummary(constraints.maxWidth >= _wideLayoutWidth),
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
                            label: "Search",
                            onSearch: (query) =>
                                _viewModel.filterSearch = query,
                          ),
                        ),
                        FilterButton(
                          active: _viewModel.hasFilters,
                          collapsed:
                              constraints.maxWidth < FilterButton.collapseWidth,
                          onPressed: () => RoutinesFilterDialog.show(
                            context,
                            viewModel: _viewModel,
                          ),
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
        if (routines.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildPlaceholder(context),
          )
        else
          SliverFixedExtentList.builder(
            itemExtent: RoundedListTile.extentFor(subtitle: true),
            itemCount: routines.length,
            itemBuilder: (context, index) =>
                _RoutineTile(routine: routines[index]),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: _fabPadding)),
      ],
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
    final count = _viewModel.resultCount;
    if (count == null) return const SizedBox.shrink();
    final total = _viewModel.totalCount;
    if (total == 0) return const SizedBox.shrink();
    final label = _viewModel.isFiltered && total != null && total != count
        ? "$count of $total"
        : "$count ${count == 1 ? "routine" : "routines"}";
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (_viewModel.isFiltered) {
      return Center(child: Text("No matching routines.", style: style));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text("No routines yet.", style: style),
          FilledButton.icon(
            onPressed: () => context.go("/practice/routines/create"),
            icon: const Icon(Symbols.add),
            label: const Text("Create routine"),
          ),
        ],
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
                  _formatDuration(practiced),
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
  final PracticeRoutine routine;

  const _RoutineTile({required this.routine});

  String get _subtitle {
    final count = routine.exerciseCount;
    final exercises = "$count ${count == 1 ? "exercise" : "exercises"}";
    if (routine.targetDuration == Duration.zero) return exercises;
    return "$exercises • ${_formatDuration(routine.targetDuration)}";
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
