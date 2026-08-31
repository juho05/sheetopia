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
                        : () {
                            // TODO
                          },
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
                child: _buildBody(context, routine),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PracticeRoutine? routine) {
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
          itemBuilder: (context, index) =>
              _RoutineEntryTile(entry: routine.entries[index]),
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

  const _RoutineEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetDuration = entry.targetDuration;
    return ExerciseTile(
      exercise: entry.exercise,
      showCategory: true,
      trailing: Padding(
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
    );
  }
}
