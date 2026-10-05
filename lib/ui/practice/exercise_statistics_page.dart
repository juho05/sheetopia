/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/practice/duration_bar_chart.dart';
import 'package:sheetopia/ui/practice/exercise_duration_bar.dart';
import 'package:sheetopia/ui/practice/exercise_statistics_viewmodel.dart';

class ExerciseStatisticsPage extends StatefulWidget {
  final DateTime Function()? clock;

  const ExerciseStatisticsPage({super.key, this.clock});

  @override
  State<ExerciseStatisticsPage> createState() => _ExerciseStatisticsPageState();
}

class _ExerciseStatisticsPageState extends State<ExerciseStatisticsPage> {
  static const double _maxWidth = 900;
  static const double _rowPadding = 8;

  late final ExerciseStatisticsViewModel _viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ExerciseStatisticsViewModel(
      repo: context.read(),
      clock: widget.clock,
    );
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
        position.maxScrollExtent -
            3 * (ExerciseDurationBar.heightOf(context) + 2 * _rowPadding);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Practiced exercises"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => _buildContent(
              context,
              16 +
                  ((constraints.maxWidth - _maxWidth) / 2).clamp(
                    0,
                    double.infinity,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double horizontalPadding) {
    final exercises = _viewModel.exercises;
    final longest = _viewModel.longest;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            8,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                SegmentedButton<ExerciseStatisticsRange>(
                  showSelectedIcon: false,
                  style: compactSegmentStyle,
                  segments: const [
                    ButtonSegment(
                      value: ExerciseStatisticsRange.week,
                      label: Text("7 days"),
                    ),
                    ButtonSegment(
                      value: ExerciseStatisticsRange.month,
                      label: Text("30 days"),
                    ),
                    ButtonSegment(
                      value: ExerciseStatisticsRange.threeMonths,
                      label: Text("90 days"),
                    ),
                    ButtonSegment(
                      value: ExerciseStatisticsRange.year,
                      label: Text("Year"),
                    ),
                    ButtonSegment(
                      value: ExerciseStatisticsRange.all,
                      label: Text("All"),
                    ),
                  ],
                  selected: {_viewModel.range},
                  onSelectionChanged: (selection) {
                    _viewModel.range = selection.first;
                    _scrollToTop();
                  },
                ),
                SearchInput(
                  label: "Search",
                  onSearch: (query) {
                    _viewModel.filterSearch = query;
                    _scrollToTop();
                  },
                ),
              ],
            ),
          ),
        ),
        if (exercises.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildPlaceholder(context),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverFixedExtentList.builder(
              itemExtent:
                  ExerciseDurationBar.heightOf(context) + 2 * _rowPadding,
              itemCount: exercises.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: _rowPadding),
                child: ExerciseDurationBar(
                  name: exercises[index].deleted ? null : exercises[index].name,
                  duration: exercises[index].duration,
                  longest: longest,
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final theme = Theme.of(context);
    return Center(
      child: Text(
        _viewModel.isFiltered ? "No matching exercises." : "No exercises yet.",
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
