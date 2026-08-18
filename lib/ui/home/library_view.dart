/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/home/filter_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';
import 'package:sheetopia/ui/home/sliver_score_grid.dart';

class _SelectAllScoresIntent extends Intent {
  const _SelectAllScoresIntent();
}

class _SelectAllScoresAction extends Action<_SelectAllScoresIntent> {
  final void Function() _onInvoke;

  _SelectAllScoresAction(this._onInvoke);

  // a focused text field owns ctrl+a for its own content
  @override
  bool get isActionEnabled =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() ==
      null;

  @override
  void invoke(_SelectAllScoresIntent intent) => _onInvoke();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

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
  String? _rangeAnchorId;

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
    _rangeAnchorId = score.id;
    widget.onScoreSelected?.call(score);
  }

  void _deselectScore(Score score) {
    _rangeAnchorId = score.id;
    widget.onScoreDeselected?.call(score);
  }

  void _selectRangeTo(Score score) {
    final scores = _viewModel.scores;
    final anchorId = _rangeAnchorId;
    final anchor = anchorId == null || !widget.selectionMode
        ? -1
        : scores.indexWhere((s) => s.id == anchorId);
    if (anchor < 0) {
      _selectScore(score);
      return;
    }
    final target = scores.indexWhere((s) => s.id == score.id);
    if (target < 0) return;
    widget.onScoresSelected?.call([
      for (var i = min(anchor, target); i <= max(anchor, target); i++)
        scores[i].id,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    return Shortcuts(
      shortcuts: {
        if (widget.onScoresSelected != null)
          SingleActivator(
            LogicalKeyboardKey.keyA,
            control: !isApple,
            meta: isApple,
          ): const _SelectAllScoresIntent(),
        if (widget.selectionMode && widget.onClearSelection != null)
          const SingleActivator(LogicalKeyboardKey.escape):
              const _ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          _SelectAllScoresIntent: _SelectAllScoresAction(_selectAll),
          _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
            onInvoke: (_) => widget.onClearSelection?.call(),
          ),
        },
        child: FocusScope(
          node: _focusScope,
          autofocus: true,
          child: _buildBody(context),
        ),
      ),
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
                                debounce: null,
                                onSearch: (query) {
                                  _viewModel.filterSearch = query;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ListenableBuilder(
                                listenable: _viewModel,
                                builder: (context, _) {
                                  final filterActive =
                                      _viewModel.filterComposer.isNotEmpty ||
                                      _viewModel.filterSource.isNotEmpty ||
                                      _viewModel.filterInstruments.isNotEmpty ||
                                      _viewModel.filterGenres.isNotEmpty ||
                                      _viewModel.filterTags.isNotEmpty;
                                  final icon = filterActive
                                      ? const Icon(Icons.filter_alt)
                                      : const Icon(Icons.filter_alt_outlined);
                                  return Builder(
                                    builder: (context) {
                                      if (crossAxisExtent < 500) {
                                        return IconButton(
                                          icon: icon,
                                          onPressed: () {
                                            FilterDialog.show(
                                              context,
                                              viewModel: _viewModel,
                                            );
                                          },
                                        );
                                      }
                                      if (filterActive) {
                                        return FilledButton.icon(
                                          icon: icon,
                                          label: const Text("Filter"),
                                          onPressed: () {
                                            FilterDialog.show(
                                              context,
                                              viewModel: _viewModel,
                                            );
                                          },
                                        );
                                      }
                                      return OutlinedButton.icon(
                                        icon: icon,
                                        label: const Text("Filter"),
                                        onPressed: () {
                                          FilterDialog.show(
                                            context,
                                            viewModel: _viewModel,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
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
