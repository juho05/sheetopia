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
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/section_header.dart';
import 'package:sheetopia/ui/common/selection/selectable_tile_icon.dart';
import 'package:sheetopia/ui/common/selection/selection_gestures.dart';
import 'package:sheetopia/ui/common/selection/selection_shortcuts.dart';
import 'package:sheetopia/ui/practice/delete_routine_dialog.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';
import 'package:sheetopia/ui/practice/routines_filter_dialog.dart';

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return "${minutes}min";
  return "${hours}h ${minutes}min";
}

class PracticePage extends StatefulWidget {
  final PracticeRoutinesViewModel viewModel;

  final bool selectionMode;
  final void Function(PracticeRoutine routine)? onRoutineSelected;
  final void Function(PracticeRoutine routine)? onRoutineDeselected;
  final void Function(List<String> routineIds)? onRoutinesSelected;
  final void Function()? onClearSelection;
  final Set<String> selected;

  const PracticePage({
    super.key,
    required this.viewModel,
    this.selectionMode = false,
    this.onRoutineSelected,
    this.onRoutineDeselected,
    this.onRoutinesSelected,
    this.onClearSelection,
    this.selected = const {},
  });

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  static const double _fabPadding = 88;
  static const double _horizontalPadding = RoundedListTile.horizontalMargin;
  static const double _wideLayoutWidth = 560;

  late final PracticeRoutinesViewModel _viewModel = widget.viewModel;

  final ScrollController _scrollController = ScrollController();
  final FocusScopeNode _focusScope = FocusScopeNode();
  final RangeSelectionAnchor _rangeAnchor = RangeSelectionAnchor();

  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _viewModel.loadNextPage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialPages().then(
        (_) => _scrollController.addListener(_checkEndReached),
      );
    });
  }

  @override
  void didUpdateWidget(PracticePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectionMode) _rangeAnchor.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = Visibility.of(context);
    if (visible == _visible) return;
    _visible = visible;
    if (visible) _focusScope.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkEndReached);
    _scrollController.dispose();
    _focusScope.dispose();
    super.dispose();
  }

  Future<void> _selectAll() async {
    final onRoutinesSelected = widget.onRoutinesSelected;
    if (onRoutinesSelected == null) return;
    final routineIds = await _viewModel.getFilteredRoutineIds();
    if (!mounted) return;
    onRoutinesSelected(routineIds);
  }

  void _selectRoutine(PracticeRoutine routine) {
    _rangeAnchor.anchor = routine.id;
    widget.onRoutineSelected?.call(routine);
  }

  void _deselectRoutine(PracticeRoutine routine) {
    _rangeAnchor.anchor = routine.id;
    widget.onRoutineDeselected?.call(routine);
  }

  void _toggleRoutine(PracticeRoutine routine) {
    if (widget.selected.contains(routine.id)) {
      _deselectRoutine(routine);
    } else {
      _selectRoutine(routine);
    }
  }

  void _selectRangeTo(PracticeRoutine routine) {
    final range = _rangeAnchor.rangeTo(_viewModel.loadedRoutineIds, routine.id);
    if (range == null) {
      _selectRoutine(routine);
      return;
    }
    widget.onRoutinesSelected?.call(range);
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
    return SelectionShortcuts(
      onSelectAll: widget.onRoutinesSelected != null ? _selectAll : null,
      onClearSelection: widget.selectionMode ? widget.onClearSelection : null,
      focusScopeNode: _focusScope,
      child: LayoutBuilder(
        builder: (context, constraints) => ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _buildContent(context, constraints),
        ),
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
            itemBuilder: (context, index) => _RoutineTile(
              routine: routines[index],
              selecting: widget.selectionMode,
              selected: widget.selected.contains(routines[index].id),
              onToggle: _toggleRoutine,
              onSelectionStart: widget.onRoutineSelected != null
                  ? _selectRoutine
                  : null,
              onRangeSelect:
                  widget.onRoutineSelected != null &&
                      widget.onRoutinesSelected != null
                  ? _selectRangeTo
                  : null,
              onDuplicate: () => _viewModel.duplicate(routines[index].id),
              onDelete: () => _delete(routines[index]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: _fabPadding)),
      ],
    );
  }

  Future<void> _delete(PracticeRoutine routine) async {
    if (!await confirmDeleteRoutine(context, routine.name)) return;
    await _viewModel.delete(routine.id);
  }

  Widget _buildSummary(bool wide) {
    const today = _TodayCard(practiced: Duration.zero);
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
  final bool selecting;
  final bool selected;
  final void Function(PracticeRoutine routine) onToggle;
  final void Function(PracticeRoutine routine)? onSelectionStart;
  final void Function(PracticeRoutine routine)? onRangeSelect;
  final void Function() onDuplicate;
  final void Function() onDelete;

  const _RoutineTile({
    required this.routine,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
    this.onSelectionStart,
    this.onRangeSelect,
  });

  String get _subtitle {
    final count = routine.exerciseCount;
    final exercises = "$count ${count == 1 ? "exercise" : "exercises"}";
    if (routine.targetDuration == Duration.zero) return exercises;
    return "$exercises • ${_formatDuration(routine.targetDuration)}";
  }

  @override
  Widget build(BuildContext context) {
    final gestures = SelectionGestures(
      item: routine,
      selecting: selecting,
      onToggle: onToggle,
      onSelectionStart: onSelectionStart,
      onRangeSelect: onRangeSelect,
      onActivate: () => context.go("/practice/routines/${routine.id}/details"),
    );
    return RoundedListTile(
      leading: SelectableTileIcon(
        icon: Symbols.checklist,
        selecting: selecting,
        selected: selected,
      ),
      title: routine.name,
      selected: selected,
      subtitle: Text(_subtitle),
      onTap: gestures.onTap,
      onLongPress: gestures.onLongPress,
      trailing: selecting
          ? null
          : MenuButton(
              options: [
                ContextMenuOption(
                  icon: Symbols.edit,
                  title: "Edit",
                  onSelected: () =>
                      context.go("/practice/routines/${routine.id}/edit"),
                ),
                ContextMenuOption(
                  icon: Symbols.content_copy,
                  title: "Duplicate",
                  onSelected: onDuplicate,
                ),
                ContextMenuOption(
                  icon: Symbols.delete,
                  title: "Delete",
                  onSelected: onDelete,
                ),
              ],
            ),
    );
  }
}
