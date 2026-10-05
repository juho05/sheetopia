/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_statistics.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/surface.dart';
import 'package:sheetopia/ui/practice/duration_bar_chart.dart';
import 'package:sheetopia/ui/practice/exercise_duration_bar.dart';
import 'package:sheetopia/ui/practice/practice_statistics_viewmodel.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';
import 'package:sheetopia/ui/practice/statistics_period_dialog.dart';

class PracticeStatisticsPage extends StatefulWidget {
  final DateTime Function()? clock;

  const PracticeStatisticsPage({super.key, this.clock});

  @override
  State<PracticeStatisticsPage> createState() => _PracticeStatisticsPageState();
}

class _PracticeStatisticsPageState extends State<PracticeStatisticsPage> {
  static const double _maxWidth = 900;
  static const double _wideLayoutWidth = 720;
  static const double _spacing = 12;

  late final PracticeStatisticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeStatisticsViewModel(
      repo: context.read(),
      clock: widget.clock,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    _viewModel.firstWeekday = index == 0 ? DateTime.sunday : index;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickPeriod() async {
    final day = await StatisticsPeriodDialog.show(
      context,
      period: _viewModel.period,
      now: _viewModel.now,
      firstPracticed: _viewModel.firstPracticed,
    );
    if (day == null) return;
    _viewModel.goTo(day);
  }

  String _periodLabel(StatisticsPeriod period) {
    final start = period.start;
    final last = period.lastDay;
    switch (period.frame) {
      case StatisticsTimeFrame.week:
        return "${DateFormat.MMMd().format(start)} - "
            "${DateFormat.yMMMd().format(last)}";
      case StatisticsTimeFrame.month:
        return DateFormat.yMMMM().format(start);
      case StatisticsTimeFrame.threeMonths:
        final from = start.year == last.year
            ? DateFormat.MMM().format(start)
            : DateFormat.yMMM().format(start);
        return "$from - ${DateFormat.yMMM().format(last)}";
      case StatisticsTimeFrame.year:
        return "${start.year}";
    }
  }

  List<String> _bucketLabels() {
    final format = switch ((_viewModel.resolution, _viewModel.timeFrame)) {
      (StatisticsResolution.day, StatisticsTimeFrame.week) => DateFormat.E(),
      (StatisticsResolution.day, StatisticsTimeFrame.month) => DateFormat.d(),
      (StatisticsResolution.month, _) => DateFormat.MMM(),
      _ => DateFormat.MMMd(),
    };
    return [for (final b in _viewModel.buckets) format.format(b.start)];
  }

  String _bucketTitle(StatisticsBucket bucket) =>
      switch (_viewModel.resolution) {
        StatisticsResolution.day => DateFormat.yMMMEd().format(bucket.start),
        StatisticsResolution.week =>
          "${DateFormat.MMMd().format(bucket.start)} - "
              "${DateFormat.MMMd().format(bucket.lastDay)}",
        StatisticsResolution.month => DateFormat.yMMMM().format(bucket.start),
      };

  List<String> _weekdayLabels() {
    final format = DateFormat.E();
    return [
      for (var i = 0; i < 7; i++)
        // 2024-01-01 is a Monday
        format.format(
          DateTime(2024, 1, (_viewModel.firstWeekday - 1 + i) % 7 + 1),
        ),
    ];
  }

  List<String> _hourLabels(BuildContext context) {
    final format = MediaQuery.alwaysUse24HourFormatOf(context)
        ? DateFormat.Hm()
        : DateFormat.j();
    return [
      for (var h = 0; h < 24; h++) format.format(DateTime(2024, 1, 1, h)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Statistics"),
        actions: [
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) => IconButton(
              tooltip: "Today",
              icon: const Icon(Symbols.today),
              onPressed: _viewModel.isCurrent ? null : _viewModel.goToToday,
            ),
          ),
          TextButton.icon(
            onPressed: () => context.go("/practice/statistics/records"),
            icon: const Icon(Symbols.edit_note),
            label: const Text("Records"),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.loading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            return LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      16 +
                      ((constraints.maxWidth - _maxWidth) / 2).clamp(
                        0,
                        double.infinity,
                      ),
                  vertical: 8,
                ),
                children: _buildSections(
                  context,
                  constraints.maxWidth >= _wideLayoutWidth,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, bool wide) {
    final empty = _viewModel.total == Duration.zero;
    final weekdays = _viewModel.timeFrame == StatisticsTimeFrame.week
        ? null
        : _Card(
            title: "Weekdays",
            child: DurationBarChart(
              height: 140,
              values: _viewModel.weekdays,
              labels: _weekdayLabels(),
            ),
          );
    final hours = _Card(
      title: "Time of day",
      child: DurationBarChart(
        height: 140,
        values: _viewModel.hours,
        labels: _hourLabels(context),
      ),
    );
    return [
      SegmentedButton<StatisticsTimeFrame>(
        showSelectedIcon: false,
        style: compactSegmentStyle,
        segments: const [
          ButtonSegment(value: StatisticsTimeFrame.week, label: Text("Week")),
          ButtonSegment(value: StatisticsTimeFrame.month, label: Text("Month")),
          ButtonSegment(
            value: StatisticsTimeFrame.threeMonths,
            label: Text("3 months"),
          ),
          ButtonSegment(value: StatisticsTimeFrame.year, label: Text("Year")),
        ],
        selected: {_viewModel.timeFrame},
        onSelectionChanged: (selection) =>
            _viewModel.timeFrame = selection.first,
      ),
      const SizedBox(height: _spacing),
      _buildTimeCard(context),
      const SizedBox(height: _spacing),
      Row(
        spacing: _spacing,
        children: [
          Expanded(
            child: _StatTile(
              label: "Active days",
              value: "${_viewModel.daysPracticed} of ${_viewModel.elapsedDays}",
            ),
          ),
          Expanded(
            child: _StatTile(
              label: "Streak",
              value: _formatDays(_viewModel.currentStreak),
            ),
          ),
          Expanded(
            child: _StatTile(
              label: "Best streak",
              value: _formatDays(_viewModel.longestStreak),
            ),
          ),
        ],
      ),
      const SizedBox(height: _spacing),
      _Card(
        title: "Top exercises",
        onTap: () => context.go("/practice/statistics/exercises"),
        child: empty
            ? const _Placeholder(text: "Nothing practiced in this period.")
            : _TopExercises(exercises: _viewModel.topExercises),
      ),
      if (!empty) ...[
        const SizedBox(height: _spacing),
        if (wide && weekdays != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: _spacing,
            children: [
              Expanded(child: weekdays),
              Expanded(child: hours),
            ],
          )
        else ...[
          if (weekdays != null) ...[weekdays, const SizedBox(height: _spacing)],
          hours,
        ],
      ],
      const SizedBox(height: _spacing),
    ];
  }

  static String _formatDays(int days) => "$days ${days == 1 ? "day" : "days"}";

  Widget _buildTimeCard(BuildContext context) {
    final theme = Theme.of(context);
    final buckets = _viewModel.buckets;
    final selected = _viewModel.selectedBucket;
    final bucket = selected == null ? null : buckets[selected];
    final resolutions = _viewModel.timeFrame.resolutions;
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w500,
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: "Previous",
                icon: const Icon(Symbols.chevron_left),
                onPressed: _viewModel.previous,
              ),
              Expanded(
                child: Center(
                  child: TextButton(
                    onPressed: _pickPeriod,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _periodLabel(_viewModel.period),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Symbols.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: "Next",
                icon: const Icon(Symbols.chevron_right),
                onPressed: _viewModel.hasNext ? _viewModel.next : null,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bucket == null ? "Total" : _bucketTitle(bucket),
                      overflow: TextOverflow.ellipsis,
                      style: captionStyle,
                    ),
                    Text(
                      formatPracticed(bucket?.duration ?? _viewModel.total),
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Daily average", style: captionStyle),
                  Text(
                    formatPracticed(_viewModel.dailyAverage),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
          DurationBarChart(
            values: [for (final b in buckets) b.duration],
            labels: _bucketLabels(),
            selected: selected,
            onSelected: (index) => _viewModel.selectedBucket = index,
          ),
          if (resolutions.length > 1)
            Center(
              child: SegmentedButton<StatisticsResolution>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: [
                  for (final resolution in StatisticsResolution.values)
                    if (resolutions.contains(resolution))
                      ButtonSegment(
                        value: resolution,
                        label: Text(switch (resolution) {
                          StatisticsResolution.day => "Days",
                          StatisticsResolution.week => "Weeks",
                          StatisticsResolution.month => "Months",
                        }),
                      ),
                ],
                selected: {_viewModel.resolution},
                onSelectionChanged: (selection) =>
                    _viewModel.resolution = selection.first,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;

  /// Adds an arrow next to the title.
  final void Function()? onTap;

  const _Card({this.title, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final theme = Theme.of(context);
    return Material(
      color: Surface.raisedOf(context),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Surface.tile(
            context,
            child: title == null
                ? child
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      Row(
                        spacing: 12,
                        children: [
                          Expanded(child: Heading(text: title)),
                          if (onTap != null)
                            Icon(
                              Symbols.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                      child,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Surface.raisedOf(context),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String text;

  const _Placeholder({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TopExercises extends StatelessWidget {
  final List<ExerciseStatistic> exercises;

  const _TopExercises({required this.exercises});

  @override
  Widget build(BuildContext context) {
    final longest = exercises.first.duration;
    return Column(
      spacing: 12,
      children: [
        for (final exercise in exercises)
          ExerciseDurationBar(
            name: exercise.name,
            duration: exercise.duration,
            longest: longest,
          ),
      ],
    );
  }
}
