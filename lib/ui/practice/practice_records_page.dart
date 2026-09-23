/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';
import 'package:sheetopia/ui/practice/practice_record_dialog.dart';
import 'package:sheetopia/ui/practice/practice_records_viewmodel.dart';
import 'package:sheetopia/ui/practice/routine_summary.dart';

class PracticeRecordsPage extends StatefulWidget {
  const PracticeRecordsPage({super.key});

  @override
  State<PracticeRecordsPage> createState() => _PracticeRecordsPageState();
}

class _PracticeRecordsPageState extends State<PracticeRecordsPage> {
  static const double _fabPadding = 88;
  static const String _deletedExercise = "Deleted exercise";

  late final PracticeRecordsViewModel _viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeRecordsViewModel(repo: context.read());
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
        position.maxScrollExtent - 3 * RoundedListTile.defaultHeight;
  }

  Future<void> _create() async {
    final input = await PracticeRecordDialog.create(context);
    if (input == null) return;
    await _viewModel.create(
      exerciseId: input.exerciseId,
      startedAt: input.startedAt,
      duration: input.duration,
    );
  }

  Future<void> _edit(PracticeRecordItem item) async {
    final record = item.record;
    final input = await PracticeRecordDialog.edit(
      context,
      exerciseId: record.exerciseId,
      exerciseName: item.exerciseName ?? _deletedExercise,
      startedAt: record.startedAt,
      duration: record.duration,
    );
    if (input == null) return;
    await _viewModel.update(
      record.id,
      startedAt: input.startedAt,
      duration: input.duration,
    );
  }

  Future<void> _delete(PracticeRecordItem item) async {
    final confirmed = await ConfirmationDialog.showCancel(
      context,
      title: "Delete record?",
      message: "The record will be deleted on all your devices.",
    );
    if (!confirmed) return;
    await _viewModel.delete(item.record.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const Text("Practice records")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Symbols.add),
        label: const Text("Add record"),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final records = _viewModel.records;
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (records.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildPlaceholder(context),
          )
        else
          SliverFixedExtentList.builder(
            itemExtent: RoundedListTile.extentFor(subtitle: true),
            itemCount: records.length,
            itemBuilder: (context, index) => _RecordTile(
              item: records[index],
              exerciseName: records[index].exerciseName ?? _deletedExercise,
              onEdit: () => _edit(records[index]),
              onDelete: () => _delete(records[index]),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: _fabPadding)),
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
        "No practice records yet.",
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final PracticeRecordItem item;
  final String exerciseName;
  final void Function() onEdit;
  final void Function() onDelete;

  const _RecordTile({
    required this.item,
    required this.exerciseName,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatStart(BuildContext context) {
    final startedAt = item.record.startedAt;
    final localizations = MaterialLocalizations.of(context);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(startedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final now = DateTime.now();
    if (PracticeProgress.sameDay(startedAt, now)) return "Today, $time";
    final yesterday = PracticeProgress.startOfDay(
      now,
    ).subtract(const Duration(hours: 12));
    if (PracticeProgress.sameDay(startedAt, yesterday)) {
      return "Yesterday, $time";
    }
    return "${localizations.formatMediumDate(startedAt)}, $time";
  }

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final running = record.running;
    final subtitle = [
      _formatStart(context),
      running ? "Running" : formatPracticed(record.duration),
      ?item.routineName,
    ].join(" • ");
    return RoundedListTile(
      leading: const RoundedTileIcon(icon: Symbols.timer),
      title: exerciseName,
      subtitle: Text(subtitle),
      onTap: running ? null : onEdit,
      trailing: running
          ? null
          : MenuButton(
              options: [
                ContextMenuOption(
                  icon: Symbols.edit,
                  title: "Edit",
                  onSelected: onEdit,
                ),
                ContextMenuOption(
                  icon: Symbols.delete,
                  title: "Delete",
                  onSelected: onDelete,
                ),
              ],
            ),
    );
  }
}
