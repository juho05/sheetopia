/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/filter_button.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/selection/selection_gestures.dart';
import 'package:sheetopia/ui/common/selection/selection_shortcuts.dart';
import 'package:sheetopia/ui/home/filter_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';
import 'package:sheetopia/ui/home/sliver_score_grid.dart';

class LibraryView extends StatefulWidget {
  final LibraryViewModel viewModel;

  final void Function()? onScrollDown;
  final void Function()? onScrollUp;

  final bool selectionMode;
  final void Function(Score score)? onScoreSelected;
  final void Function(Score score)? onScoreDeselected;
  final void Function(List<String> scoreIds)? onScoresSelected;
  final void Function()? onClearSelection;
  final Set<String> selected;

  const LibraryView({
    super.key,
    required this.viewModel,
    this.onScrollDown,
    this.onScrollUp,
    this.selectionMode = false,
    this.onScoreSelected,
    this.onScoreDeselected,
    this.onScoresSelected,
    this.onClearSelection,
    this.selected = const {},
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel = widget.viewModel;

  final ScrollController _scrollController = ScrollController();
  final FocusScopeNode _focusScope = FocusScopeNode();

  bool _visible = true;

  final RangeSelectionAnchor _rangeAnchor = RangeSelectionAnchor();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _viewModel.loadNextPage();
    Future.delayed(const Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _loadInitialPages().then((value) {
          _scrollController.addListener(_checkEndReached);
        });
      });
    });
  }

  @override
  void didUpdateWidget(LibraryView oldWidget) {
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

  void _onScroll() {
    _onScrollChanged(_scrollController.position.userScrollDirection);
  }

  ScrollDirection? _lastDirection;
  Timer? _onScrollChangedDebounce;

  void _onScrollChanged(ScrollDirection direction) {
    if (direction == _lastDirection) return;
    _lastDirection = direction;
    _onScrollChangedDebounce?.cancel();
    _onScrollChangedDebounce = Timer(const Duration(milliseconds: 50), () {
      if (direction == ScrollDirection.reverse) {
        widget.onScrollDown?.call();
      } else {
        widget.onScrollUp?.call();
      }
    });
  }

  Future<void> _loadInitialPages() async {
    while (context.mounted && _isBottom && _viewModel.hasNextPage) {
      await _viewModel.loadNextPage();
    }
  }

  @override
  void dispose() {
    _onScrollChangedDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_checkEndReached);
    _scrollController.dispose();
    _focusScope.dispose();
    super.dispose();
  }

  void _checkEndReached() {
    if (_isBottom) _viewModel.loadNextPage();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    if (!position.hasContentDimensions || !position.hasPixels) return false;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 3 * ScoreGridCell.height);
  }

  Future<void> _selectAll() async {
    final onScoresSelected = widget.onScoresSelected;
    if (onScoresSelected == null) return;
    final scoreIds = await _viewModel.getFilteredScoreIds();
    if (!mounted) return;
    onScoresSelected(scoreIds);
  }

  void _selectScore(Score score) {
    _rangeAnchor.anchor = score.id;
    widget.onScoreSelected?.call(score);
  }

  void _deselectScore(Score score) {
    _rangeAnchor.anchor = score.id;
    widget.onScoreDeselected?.call(score);
  }

  void _selectRangeTo(Score score) {
    final range = _rangeAnchor.rangeTo([
      for (final s in _viewModel.scores) s.id,
    ], score.id);
    if (range == null) {
      _selectScore(score);
      return;
    }
    widget.onScoresSelected?.call(range);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionShortcuts(
      onSelectAll: widget.onScoresSelected != null ? _selectAll : null,
      onClearSelection: widget.selectionMode ? widget.onClearSelection : null,
      focusScopeNode: _focusScope,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _onScrollChanged(
            event.scrollDelta.dy < 0
                ? ScrollDirection.forward
                : ScrollDirection.reverse,
          );
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.kind == PointerDeviceKind.mouse ||
              details.delta.dy.abs() < 0.5) {
            return;
          }
          _onScrollChanged(
            details.delta.dy > 0
                ? ScrollDirection.forward
                : ScrollDirection.reverse,
          );
        },
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final crossAxisExtent = viewportConstraints.maxWidth;
            return CustomScrollView(
              controller: _scrollController,
              scrollCacheExtent: const ScrollCacheExtent.pixels(
                ScoreGridCell.height * 2.0,
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SearchInput(
                                label: "Search",
                                onSearch: (query) {
                                  _viewModel.filterSearch = query;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ListenableBuilder(
                                listenable: _viewModel,
                                builder: (context, _) => FilterButton(
                                  active:
                                      _viewModel.filterComposer.isNotEmpty ||
                                      _viewModel.filterSource.isNotEmpty ||
                                      _viewModel.filterInstruments.isNotEmpty ||
                                      _viewModel.filterGenres.isNotEmpty ||
                                      _viewModel.filterTags.isNotEmpty,
                                  collapsed:
                                      crossAxisExtent <
                                      FilterButton.collapseWidth,
                                  onPressed: () => FilterDialog.show(
                                    context,
                                    viewModel: _viewModel,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ListenableBuilder(
                          listenable: _viewModel,
                          builder: (context, _) {
                            final count = _viewModel.resultCount;
                            if (count == null) return const SizedBox.shrink();
                            final total = _viewModel.totalCount;
                            final label =
                                _viewModel.isFiltered &&
                                    total != null &&
                                    total != count
                                ? "$count of $total"
                                : "$count ${count == 1 ? "score" : "scores"}";
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
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, _) {
                    return SliverScoreGrid(
                      scores: _viewModel.scores,
                      crossAxisExtent: crossAxisExtent,
                      onScoreSelected: widget.onScoreSelected != null
                          ? _selectScore
                          : null,
                      onScoreDeselected: widget.onScoreDeselected != null
                          ? _deselectScore
                          : null,
                      onScoreRangeSelect:
                          widget.onScoreSelected != null &&
                              widget.onScoresSelected != null
                          ? _selectRangeTo
                          : null,
                      selectionMode: widget.selectionMode,
                      selected: widget.selected,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
