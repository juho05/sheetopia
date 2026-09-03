/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/practice/delete_routine_dialog.dart';
import 'package:sheetopia/ui/practice/edit_routine_viewmodel.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/practice/exercise_tile.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';
import 'package:sheetopia/ui/practice/select_exercises_dialog.dart';

class EditRoutinePage extends StatelessWidget {
  static const double _maxWidth = 900;

  final String? routineId;

  const EditRoutinePage({super.key, required this.routineId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditRoutineViewModel>(
      create: (context) =>
          EditRoutineViewModel(repo: context.read(), routineId: routineId),
      builder: (context, _) {
        return Consumer<EditRoutineViewModel>(
          builder: (context, viewModel, _) {
            return Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: Text(
                  viewModel.isCreate ? "Create routine" : "Edit routine",
                ),
              ),
              body: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: _buildBody(context, viewModel),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, EditRoutineViewModel viewModel) {
    if (viewModel.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (viewModel.missing) {
      final theme = Theme.of(context);
      return Center(
        child: Text(
          "This routine no longer exists.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return const _EditRoutineForm();
  }
}

class _EditRoutineForm extends StatefulWidget {
  const _EditRoutineForm();

  @override
  State<_EditRoutineForm> createState() => _EditRoutineFormState();
}

class _EditRoutineFormState extends State<_EditRoutineForm> {
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _addExercises(
    BuildContext context,
    EditRoutineViewModel viewModel,
  ) async {
    final exerciseIds = await SelectExercisesDialog.show(context);
    if (exerciseIds == null || exerciseIds.isEmpty) return;
    await viewModel.addExercises(exerciseIds);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditRoutineViewModel>(
      builder: (context, viewModel, _) {
        return LayoutBuilder(
          builder: (context, constraints) => _buildForm(
            context,
            viewModel,
            narrow: constraints.maxWidth < routineEntryNarrowBreakpoint,
          ),
        );
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    EditRoutineViewModel viewModel, {
    required bool narrow,
  }) {
    return ReactiveForm(
      formGroup: viewModel.form,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RoundedListTile.horizontalMargin,
                    vertical: 8,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        ReactiveTextField<String>(
                          formControlName: EditRoutineViewModel.formName,
                          focusNode: _nameFocus,
                          onTapOutside: (event) => _nameFocus.unfocus(),
                          decoration: const InputDecoration(
                            label: Text("Name"),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        ReactiveTextField<String>(
                          formControlName: EditRoutineViewModel.formDescription,
                          focusNode: _descriptionFocus,
                          onTapOutside: (event) => _descriptionFocus.unfocus(),
                          maxLines: 8,
                          minLines: 3,
                          decoration: const InputDecoration(
                            label: Text("Description"),
                            border: OutlineInputBorder(),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                          ),
                        ),
                        RoutineExercisesHeader(
                          count: viewModel.entries.length,
                          targetDuration: viewModel.targetDuration,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverReorderableList(
                  itemCount: viewModel.entries.length,
                  itemBuilder: (context, index) => _RoutineEntryTile(
                    key: ValueKey(viewModel.entries[index].id),
                    viewModel: viewModel,
                    entry: viewModel.entries[index],
                    index: index,
                    narrow: narrow,
                  ),
                  onReorderItem: viewModel.moveEntry,
                  onReorderStart: (_) {
                    HapticFeedback.lightImpact();
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RoundedListTile.horizontalMargin,
                      vertical: 8,
                    ),
                    child: _AddExercisesPlaceholder(
                      onAdd: () => _addExercises(context, viewModel),
                      loading: viewModel.exercisesLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: viewModel.isCreate
                  ? _CreateButton(viewModel: viewModel)
                  : _DeleteButton(viewModel: viewModel),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineEntryTile extends StatefulWidget {
  final EditRoutineViewModel viewModel;
  final PracticeRoutineEntry entry;
  final int index;
  final bool narrow;

  const _RoutineEntryTile({
    super.key,
    required this.viewModel,
    required this.entry,
    required this.index,
    required this.narrow,
  });

  @override
  State<_RoutineEntryTile> createState() => _RoutineEntryTileState();
}

class _RoutineEntryTileState extends State<_RoutineEntryTile> {
  static String _minutesOf(Duration? duration) =>
      duration == null ? "" : duration.inMinutes.toString();

  late final TextEditingController _durationController = TextEditingController(
    text: _minutesOf(widget.entry.targetDuration),
  );

  final _durationFocus = FocusNode();

  @override
  void didUpdateWidget(covariant _RoutineEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final minutes = _minutesOf(widget.entry.targetDuration);
    if (oldWidget.entry.targetDuration != widget.entry.targetDuration &&
        minutes != _durationController.text) {
      _durationController.text = minutes;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  void _onDurationChanged(String value) {
    final minutes = int.tryParse(value);
    widget.viewModel.setTargetDuration(
      widget.entry.id,
      minutes == null || minutes <= 0 ? null : Duration(minutes: minutes),
    );
  }

  Widget _buildDuration(BuildContext context) {
    final theme = Theme.of(context);
    return OptionalTooltip(
      message: "Target duration",
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          SizedBox(
            width: 56,
            child: TextField(
              controller: _durationController,
              focusNode: _durationFocus,
              onTapOutside: (event) => _durationFocus.unfocus(),
              onChanged: _onDurationChanged,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
                hintText: "0",
              ),
            ),
          ),
          Text(
            "min",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSelector(List<Score> scores) {
    final selected = widget.entry.defaultScoreId == null
        ? 0
        : scores.indexWhere((s) => s.id == widget.entry.defaultScoreId);
    return ExerciseScoreSelector(
      scores: scores,
      selectedIndex: selected < 0 ? 0 : selected,
      label: "Default score",
      onSelected: (index) =>
          widget.viewModel.setDefaultScore(widget.entry.id, scores[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.viewModel.scoresFor(widget.entry.exercise.id);
    final selectorBelow = widget.narrow && scores.length > 1;

    return ReorderableDelayedDragStartListener(
      index: widget.index,
      child: ExerciseTile(
        exercise: widget.entry.exercise,
        showCategory: true,
        showBadges: !widget.narrow,
        subtitle: selectorBelow ? _buildScoreSelector(scores) : null,
        leading: ReorderableDragStartListener(
          index: widget.index,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Icon(Icons.drag_handle),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            if (!selectorBelow && scores.length > 1)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: _buildScoreSelector(scores),
              ),
            _buildDuration(context),
            IconButton(
              onPressed: () => widget.viewModel.removeEntry(widget.entry.id),
              tooltip: "Remove exercise",
              icon: const Icon(Symbols.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExercisesPlaceholder extends StatelessWidget {
  final void Function() onAdd;
  final bool loading;

  const _AddExercisesPlaceholder({required this.onAdd, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(16),
        padding: const EdgeInsets.all(1),
        dashPattern: const [6, 6],
        strokeWidth: 2,
        color: theme.colorScheme.onSurface.withAlpha(160),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, minHeight: 40),
            child: loading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : Button(
                    onPressed: onAdd,
                    icon: Symbols.add,
                    darkTonal: true,
                    child: const Text("Add exercises"),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final EditRoutineViewModel viewModel;

  const _CreateButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConsumer(
      builder: (context, form, _) => FilledButton(
        onPressed: form.valid
            ? () async {
                await viewModel.create();
                if (!context.mounted) return;
                context.pop();
              }
            : null,
        child: const Text("Create"),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final EditRoutineViewModel viewModel;

  const _DeleteButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      onPressed: () async {
        final name = viewModel.name;
        if (!await confirmDeleteRoutine(context, name)) return;
        await viewModel.delete();
        Toast.show("Successfully deleted routine '$name'!");
        if (!context.mounted) return;
        context.pop();
      },
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      icon: const Icon(Icons.delete_outline),
      label: const Text("Delete"),
    );
  }
}
