/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/surface.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/practice/practice_stopwatch.dart';
import 'package:sheetopia/ui/practice/practice_timer.dart';
import 'package:url_launcher/url_launcher.dart';

class _OverlayCard extends StatelessWidget {
  static const double maxWidth = 560;

  final List<Widget> content;
  final List<Widget> actions;

  const _OverlayCard({required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Card(
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Surface(
                        level: SurfaceLevel.dialog,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 12,
                                  children: content,
                                ),
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 8,
                              children: actions,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseStartOverlay extends StatelessWidget {
  final Exercise exercise;

  final String? routineName;
  final int? position;
  final int? length;

  final Duration? target;
  final Duration practiced;

  final bool hasPrevious;
  final bool hasNext;

  final List<Score> scores;
  final int selectedScoreIndex;
  final void Function(int index)? onScoreSelected;

  final void Function()? onStart;
  final void Function()? onReset;
  final void Function() onLeave;
  final void Function()? onPrevious;
  final void Function()? onNext;

  const ExerciseStartOverlay({
    super.key,
    required this.exercise,
    required this.practiced,
    this.routineName,
    this.position,
    this.length,
    this.target,
    this.hasPrevious = false,
    this.hasNext = false,
    this.scores = const [],
    this.selectedScoreIndex = -1,
    this.onScoreSelected,
    required this.onStart,
    this.onReset,
    required this.onLeave,
    this.onPrevious,
    this.onNext,
  });

  Widget _buildMeta(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final routineName = this.routineName;
    final position = this.position;
    final length = this.length;
    final target = this.target;
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (routineName != null) Text(routineName, style: style),
        if (position != null && length != null)
          Text("Exercise ${position + 1} of $length", style: style),
        if (target != null)
          Text("Target ${formatStopwatch(target)}", style: style),
        if (practiced > Duration.zero)
          Text(
            "${formatStopwatch(practiced)} practiced",
            style: style?.copyWith(
              color: target != null && practiced > target
                  ? overTargetColor(context)
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildScoreSelector(
    BuildContext context,
    void Function(int index) onSelected,
  ) {
    final theme = Theme.of(context);
    return Row(
      spacing: 8,
      children: [
        Text(
          "Score",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: ExerciseScoreSelector(
            scores: scores,
            selectedIndex: selectedScoreIndex,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = exercise.category;
    final onScoreSelected = this.onScoreSelected;
    final instrument = exercise.instrument;
    final description = exercise.description;
    final source = exercise.source;
    final sourceLink = exercise.sourceLink;
    final resumed = practiced > Duration.zero;
    return _OverlayCard(
      content: [
        if (category != null)
          Text(
            category.name.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.5,
            ),
          ),
        Text(
          exercise.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        _buildMeta(context),
        if (instrument != null || exercise.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (instrument != null)
                CommonBadge(
                  name: instrument,
                  tooltip: false,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              for (final tag in exercise.tags)
                TagBadge(tag: tag, tooltip: false),
            ],
          ),
        if (onScoreSelected != null && scores.length > 1)
          _buildScoreSelector(context, onScoreSelected),
        if (description != null) ...[
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
        if (source != null) _SourceLine(source: source, link: sourceLink),
      ],
      actions: [
        TextButton(onPressed: onLeave, child: const Text("Leave")),
        if (onPrevious != null)
          OutlinedButton(
            onPressed: hasPrevious ? onPrevious : null,
            child: const Text("Prev"),
          ),
        if (onNext != null)
          OutlinedButton(
            onPressed: hasNext ? onNext : null,
            child: const Text("Next"),
          ),
        if (resumed && onReset != null)
          Tooltip(
            message: "Count from zero, the time so far stays recorded",
            child: OutlinedButton(
              onPressed: onStart == null ? null : onReset,
              child: const Text("Practice again"),
            ),
          ),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Symbols.play_arrow),
          label: Text(resumed ? "Resume" : "Start"),
        ),
      ],
    );
  }
}

class _SourceLine extends StatelessWidget {
  final String source;
  final String? link;

  const _SourceLine({required this.source, this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final link = this.link;
    final text = Text(
      source,
      style: theme.textTheme.bodySmall?.copyWith(
        color: link != null
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
        decoration: link != null ? TextDecoration.underline : null,
      ),
    );
    return Row(
      spacing: 6,
      children: [
        Icon(
          Symbols.book_2,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Flexible(
          child: link == null
              ? text
              : InkWell(onTap: () => launchUrl(Uri.parse(link)), child: text),
        ),
      ],
    );
  }
}

class PracticeRecoveryOverlay extends StatefulWidget {
  final String exerciseName;
  final PracticeRecovery recovery;
  final void Function(PracticeRecoveryChoice choice) onChoice;

  const PracticeRecoveryOverlay({
    super.key,
    required this.exerciseName,
    required this.recovery,
    required this.onChoice,
  });

  @override
  State<PracticeRecoveryOverlay> createState() =>
      _PracticeRecoveryOverlayState();
}

class _PracticeRecoveryOverlayState extends State<PracticeRecoveryOverlay> {
  Timer? _ticker;

  Duration get _untilNow =>
      widget.recovery.counted +
      DateTime.now().difference(widget.recovery.leftAt);

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _scheduleTick() {
    _ticker?.cancel();
    _ticker = Timer(PracticeTimer.tickDelay(_untilNow), () {
      if (!mounted) return;
      setState(() {});
      _scheduleTick();
    });
  }

  String _formatLeftAt(BuildContext context) {
    final leftAt = widget.recovery.leftAt;
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(leftAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(leftAt.year, leftAt.month, leftAt.day);
    if (day == today) return time;
    if (day == today.subtract(const Duration(days: 1))) {
      return "yesterday at $time";
    }
    return "${localizations.formatMediumDate(leftAt)} at $time";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recovery = widget.recovery;
    final onChoice = widget.onChoice;
    final exerciseName = widget.exerciseName;
    final leftAt = _formatLeftAt(context);
    final counted = formatStopwatch(recovery.counted);
    return _OverlayCard(
      content: [
        Text(
          "Stopwatch left running",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          "$exerciseName was still being timed when the app was last open, "
          "$leftAt. Which time counts?",
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        ...buildChoiceTiles([
          ChoiceOption(
            value: PracticeRecoveryChoice.untilLeft,
            title: "Count $counted",
            subtitle:
                "Only the time until the app was last open. "
                "The stopwatch waits to be resumed.",
            leading: const Icon(Symbols.history),
          ),
          ChoiceOption(
            value: PracticeRecoveryChoice.untilNow,
            title: "Count ${formatStopwatch(_untilNow)}",
            subtitle:
                "The time until now, as if practicing never stopped. "
                "The stopwatch keeps running.",
            leading: const Icon(Symbols.timer),
          ),
          ChoiceOption(
            value: PracticeRecoveryChoice.discard,
            title: "Drop this run",
            subtitle:
                "Everything since the stopwatch was last started is dropped. "
                "Earlier practice of $exerciseName stays.",
            leading: const Icon(Symbols.delete),
          ),
        ], onChoice),
      ],
      actions: const [],
    );
  }
}
