/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/practice/practice_statistics.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class StatisticsPeriodDialog extends StatefulWidget {
  static const int _minYears = 5;

  final StatisticsPeriod period;
  final DateTime now;
  final int firstYear;

  const StatisticsPeriodDialog._({
    required this.period,
    required this.now,
    required this.firstYear,
  });

  /// Returns a day of the chosen period. No period after [now] can be chosen,
  /// years are offered back to [firstPracticed].
  static Future<DateTime?> show(
    BuildContext context, {
    required StatisticsPeriod period,
    required DateTime now,
    DateTime? firstPracticed,
  }) {
    if (period.frame == StatisticsTimeFrame.week) {
      return showDatePicker(
        context: context,
        helpText: "Select week",
        initialDate: period.start,
        firstDate: DateTime(1970),
        lastDate: now.isBefore(period.start) ? period.start : now,
      );
    }
    final firstYear = [
      now.year - _minYears + 1,
      period.start.year,
      ?firstPracticed?.year,
    ].reduce(math.min);
    return showSheetopiaDialog<DateTime>(
      context: context,
      builder: (context) => StatisticsPeriodDialog._(
        period: period,
        now: now,
        firstYear: firstYear,
      ),
    );
  }

  @override
  State<StatisticsPeriodDialog> createState() => _StatisticsPeriodDialogState();
}

class _StatisticsPeriodDialogState extends State<StatisticsPeriodDialog> {
  static const double _cellWidth = 96;
  static const double _cellHeight = 44;
  static const double _cellSpacing = 4;

  late int _year = widget.period.lastDay.year;

  bool get _years => widget.period.frame == StatisticsTimeFrame.year;

  String get _title => switch (widget.period.frame) {
    StatisticsTimeFrame.threeMonths => "Select last month",
    StatisticsTimeFrame.year => "Select year",
    _ => "Select month",
  };

  Widget _buildCell({
    required String label,
    required bool selected,
    required DateTime day,
  }) {
    final onPressed = day.isAfter(widget.now)
        ? null
        : () => Navigator.of(context).pop(day);
    return SizedBox(
      width: _cellWidth,
      height: _cellHeight,
      child: selected
          ? FilledButton.tonal(onPressed: onPressed, child: Text(label))
          : TextButton(onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _buildYears() {
    return Flexible(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: _cellSpacing,
          runSpacing: _cellSpacing,
          children: [
            for (var year = widget.now.year; year >= widget.firstYear; year--)
              _buildCell(
                label: "$year",
                selected: year == widget.period.start.year,
                day: DateTime(year),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMonths(ThemeData theme) {
    final format = DateFormat.MMM();
    return [
      Row(
        children: [
          IconButton(
            tooltip: "Previous year",
            icon: const Icon(Symbols.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Expanded(
            child: Text(
              "$_year",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: "Next year",
            icon: const Icon(Symbols.chevron_right),
            onPressed: _year < widget.now.year
                ? () => setState(() => _year++)
                : null,
          ),
        ],
      ),
      Wrap(
        spacing: _cellSpacing,
        runSpacing: _cellSpacing,
        children: [
          for (var month = 1; month <= 12; month++)
            _buildCell(
              label: format.format(DateTime(_year, month)),
              selected: widget.period.contains(DateTime(_year, month)),
              day: DateTime(_year, month),
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      maxWidth: 3 * _cellWidth + 2 * _cellSpacing + 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            _title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          if (_years) _buildYears() else ..._buildMonths(theme),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ),
        ],
      ),
    );
  }
}
