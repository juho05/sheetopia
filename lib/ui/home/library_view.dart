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
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/home/filter_dialog.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';
import 'package:sheetopia/ui/home/sliver_score_grid.dart';

class LibraryView extends StatefulWidget {
  final void Function()? onScrollDown;
  final void Function()? onScrollUp;

  final void Function(Score score)? onScoreTap;
  final Set<String> selected;

  const LibraryView({
    super.key,
    this.onScrollDown,
    this.onScrollUp,
    this.onScoreTap,
    this.selected = const {},
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _viewModel = LibraryViewModel(repo: context.read());
    _viewModel.loadNextPage();
    Future.delayed(const Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _loadInitialPages().then((value) {
          _scrollController.addListener(_checkEndReached);
        });
      });
    });
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
    _viewModel.dispose();
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

  @override
  Widget build(BuildContext context) {
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
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverLayoutBuilder(
              builder: (context, constraints) {
                return SliverToBoxAdapter(
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
                                      _viewModel.filterInstruments.isNotEmpty ||
                                      _viewModel.filterGenres.isNotEmpty ||
                                      _viewModel.filterTags.isNotEmpty;
                                  final icon = filterActive
                                      ? const Icon(Icons.filter_alt)
                                      : const Icon(Icons.filter_alt_outlined);
                                  return Builder(
                                    builder: (context) {
                                      if (constraints.crossAxisExtent < 500) {
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
                );
              },
            ),
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                return SliverScoreGrid(
                  scores: _viewModel.scores,
                  onScoreTap: widget.onScoreTap,
                  selected: widget.selected,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
