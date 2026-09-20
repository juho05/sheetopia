/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/ui/practice/practice_timer.dart';

String formatStopwatch(Duration duration) {
  if (duration.isNegative) duration = Duration.zero;
  final minutes = duration.inMinutes.remainder(60).toString();
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
  final hours = duration.inHours;
  if (hours == 0) return "$minutes:$seconds";
  return "$hours:${minutes.padLeft(2, "0")}:$seconds";
}

class PracticeTimerStopwatch extends StatelessWidget {
  final PracticeTimer timer;

  const PracticeTimerStopwatch({super.key, required this.timer});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: timer.ticks,
      builder: (context, _) => PracticeStopwatch(
        elapsed: timer.elapsed,
        target: timer.target,
        running: timer.running,
        overTarget: timer.overTarget,
        onPause: timer.pause,
        onResume: timer.resume,
      ),
    );
  }
}

Color overTargetColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.orange.shade300
    : Colors.orange.shade800;

class PracticeStopwatch extends StatelessWidget {
  final Duration elapsed;
  final Duration? target;
  final bool running;
  final bool overTarget;
  final void Function() onPause;
  final void Function() onResume;

  const PracticeStopwatch({
    super.key,
    required this.elapsed,
    required this.target,
    required this.running,
    required this.overTarget,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = this.target;
    final color = overTarget
        ? overTargetColor(context)
        : theme.colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: running ? onPause : onResume,
          icon: Icon(running ? Symbols.pause : Symbols.play_arrow),
          tooltip: running ? "Pause" : "Resume",
        ),
        Text(
          formatStopwatch(elapsed),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (target != null)
          Text(
            " / ${formatStopwatch(target)}",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}
