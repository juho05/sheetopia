/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Keeps the labels of a full width [SegmentedButton] on one line on phones.
const ButtonStyle compactSegmentStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
);

class DurationBarChart extends StatelessWidget {
  static const List<int> _axisSteps = [
    10,
    30,
    60,
    2 * 60,
    5 * 60,
    10 * 60,
    15 * 60,
    30 * 60,
    3600,
    2 * 3600,
    3 * 3600,
    6 * 3600,
    12 * 3600,
    24 * 3600,
  ];
  static const int _maxGridLines = 4;

  final List<Duration> values;

  /// One per value. Labels that would overlap are left out.
  final List<String> labels;
  final double height;
  final int? selected;

  final void Function(int? index)? onSelected;

  const DurationBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.selected,
    this.onSelected,
  }) : assert(values.length == labels.length);

  static Duration axisStep(Duration max) {
    final seconds = max.inSeconds;
    for (final step in _axisSteps) {
      if (seconds <= step * _maxGridLines) return Duration(seconds: step);
    }
    const day = Duration.secondsPerDay;
    return Duration(seconds: (seconds / _maxGridLines / day).ceil() * day);
  }

  static String formatAxis(Duration duration) {
    if (duration.inSeconds < 60) return "${duration.inSeconds}s";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return "${minutes}min";
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}min";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final max = values.fold(Duration.zero, (a, b) => b > a ? b : a);
    final step = axisStep(max);
    final lines = math.max(
      1,
      (max.inMicroseconds / step.inMicroseconds).ceil(),
    );
    final onSelected = this.onSelected;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = _BarChartPainter(
            values: values,
            labels: labels,
            step: step,
            lines: lines,
            selected: selected,
            barColor: colors.primary,
            dimmedBarColor: colors.primary.withValues(alpha: 0.35),
            gridColor: colors.outlineVariant,
            labelStyle: theme.textTheme.bodySmall!.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
          );
          final chart = CustomPaint(
            size: Size(constraints.maxWidth, height),
            painter: painter,
          );
          if (onSelected == null) return chart;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = painter.indexAt(
                details.localPosition,
                Size(constraints.maxWidth, height),
              );
              final empty = index == null || values[index] == Duration.zero;
              onSelected(empty || index == selected ? null : index);
            },
            child: chart,
          );
        },
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  static const double _topPadding = 8;
  static const double _axisGap = 8;
  static const double _labelGap = 6;
  static const double _labelSpacing = 6;
  static const double _maxBarWidth = 28;
  static const double _barFraction = 0.7;

  final List<Duration> values;
  final List<String> labels;
  final Duration step;
  final int lines;
  final int? selected;
  final Color barColor;
  final Color dimmedBarColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;

  late final List<TextPainter> _axisLabels = [
    for (var i = 1; i <= lines; i++)
      _layout(DurationBarChart.formatAxis(step * i)),
  ];
  late final List<TextPainter> _barLabels = labels.map(_layout).toList();

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.step,
    required this.lines,
    required this.selected,
    required this.barColor,
    required this.dimmedBarColor,
    required this.gridColor,
    required this.labelStyle,
    required this.textScaler,
    required this.textDirection,
  });

  TextPainter _layout(String text) => TextPainter(
    text: TextSpan(text: text, style: labelStyle),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();

  Rect _plot(Size size) {
    final axisWidth = _axisLabels.fold(0.0, (w, l) => math.max(w, l.width));
    final labelHeight = _barLabels.fold(0.0, (h, l) => math.max(h, l.height));
    return Rect.fromLTRB(
      0,
      _topPadding,
      math.max(0, size.width - axisWidth - _axisGap),
      math.max(_topPadding, size.height - labelHeight - _labelGap),
    );
  }

  int? indexAt(Offset position, Size size) {
    final plot = _plot(size);
    if (values.isEmpty || plot.width <= 0) return null;
    if (position.dx < plot.left || position.dx >= plot.right) return null;
    final slot = plot.width / values.length;
    return ((position.dx - plot.left) / slot).floor().clamp(
      0,
      values.length - 1,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = _plot(size);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= lines; i++) {
      final y = plot.bottom - plot.height * i / lines;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      if (i == 0) continue;
      final label = _axisLabels[i - 1];
      label.paint(canvas, Offset(plot.right + _axisGap, y - label.height / 2));
    }
    if (values.isEmpty || plot.width <= 0) return;

    final slot = plot.width / values.length;
    final barWidth = math.max(1.0, math.min(slot * _barFraction, _maxBarWidth));
    final radius = Radius.circular(math.min(4, barWidth / 2));
    final top = step.inMicroseconds * lines;
    for (final (i, value) in values.indexed) {
      if (value <= Duration.zero) continue;
      final barHeight = math.max(2.0, plot.height * value.inMicroseconds / top);
      final center = plot.left + slot * (i + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            center - barWidth / 2,
            plot.bottom - barHeight,
            barWidth,
            barHeight,
          ),
          topLeft: radius,
          topRight: radius,
        ),
        Paint()
          ..color = selected == null || selected == i
              ? barColor
              : dimmedBarColor,
      );
    }

    final widest = _barLabels.fold(0.0, (w, l) => math.max(w, l.width));
    final every = math.max(1, ((widest + _labelSpacing) / slot).ceil());
    for (var i = 0; i < _barLabels.length; i += every) {
      final label = _barLabels[i];
      final center = plot.left + slot * (i + 0.5);
      final x = math.max(
        0.0,
        math.min(center - label.width / 2, size.width - label.width),
      );
      label.paint(canvas, Offset(x, plot.bottom + _labelGap));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      !_listEquals(oldDelegate.values, values) ||
      !_listEquals(oldDelegate.labels, labels) ||
      oldDelegate.step != step ||
      oldDelegate.lines != lines ||
      oldDelegate.selected != selected ||
      oldDelegate.barColor != barColor ||
      oldDelegate.dimmedBarColor != dimmedBarColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textDirection != textDirection;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
