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
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/practice/exercise_tile.dart';
import 'package:sheetopia/ui/practice/routine_detail_viewmodel.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';

class RoutineDetailPage extends StatefulWidget {
  static const double _maxWidth = 900;

  final String routineId;

  const RoutineDetailPage({super.key, required this.routineId});

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late final RoutineDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RoutineDetailViewModel(
      repo: context.read(),
      routineId: widget.routineId,
    );
    _viewModel.addListener(_popWhenDeleted);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_popWhenDeleted);
    _viewModel.dispose();
    super.dispose();
  }

  void _popWhenDeleted() {
    if (!_viewModel.deleted || !mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final routine = _viewModel.routine;
        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(routine?.name ?? "Routine"),
            actions: [
              if (routine != null) ...[
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    "/practice/routines/${widget.routineId}/details/edit",
                  ),
                  icon: const Icon(Symbols.edit),
                  label: const Text("Edit"),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    onPressed: routine.entries.isEmpty
                        ? null
                        : () => context.go(
                            "/practice/routines/${widget.routineId}/details/play",
                          ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Play"),
                  ),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: RoutineDetailPage._maxWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => _buildBody(
                    context,
                    routine,
                    narrow: constraints.maxWidth < routineEntryNarrowBreakpoint,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    PracticeRoutine? routine, {
    required bool narrow,
  }) {
    if (_viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final theme = Theme.of(context);
    if (routine == null) {
      return Center(
        child: Text(
          "This routine no longer exists.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final description = routine.description;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: RoundedListTile.horizontalMargin,
            vertical: 8,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                if (description != null)
                  Text(description, style: theme.textTheme.bodyMedium),
                RoutineExercisesHeader(
                  count: routine.entries.length,
                  targetDuration: routine.targetDuration,
                ),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: routine.entries.length,
          itemBuilder: (context, index) {
            final entry = routine.entries[index];
            return _RoutineEntryTile(
              entry: entry,
              scores: _viewModel.scoresFor(entry.exercise.id),
              narrow: narrow,
              onTap: () => context.go(
                "/practice/routines/${widget.routineId}/details/play?startIndex=$index",
              ),
            );
          },
        ),
        if (routine.entries.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "No exercises yet.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }
}

class _RoutineEntryTile extends StatelessWidget {
  final PracticeRoutineEntry entry;
  final List<Score> scores;
  final bool narrow;
  final void Function() onTap;

  const _RoutineEntryTile({
    required this.entry,
    required this.scores,
    required this.narrow,
    required this.onTap,
  });

  String? get _defaultScore {
    if (scores.length < 2) return null;
    final index = scores.indexWhere((s) => s.id == entry.defaultScoreId);
    return scores[index < 0 ? 0 : index].title;
  }

  Widget _buildBadge(String name, {required bool compact}) => OptionalTooltip(
    message: name,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 160 : 200),
      child: CommonBadge(name: name, tooltip: false, compact: compact),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetDuration = entry.targetDuration;
    final defaultScore = _defaultScore;

    return ExerciseTile(
      exercise: entry.exercise,
      showCategory: true,
      onTap: onTap,
      leadingBadge: narrow && defaultScore != null
          ? _buildBadge(defaultScore, compact: true)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (!narrow && defaultScore != null)
            _buildBadge(defaultScore, compact: false),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              targetDuration == null
                  ? "No target"
                  : formatRoutineDuration(targetDuration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
