/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/home/thumbnail.dart';
import 'package:sheetopia/ui/setlists/add_scores_dialog.dart';
import 'package:sheetopia/ui/setlists/setlist_detail_viewmodel.dart';
import 'package:sheetopia/ui/setlists/setlist_name_dialog.dart';

class SetlistDetailPage extends StatefulWidget {
  static const int _thumbnailHeight = 60;
  static const int _thumbnailWidth = 48;

  final String setlistId;

  const SetlistDetailPage({super.key, required this.setlistId});

  @override
  State<SetlistDetailPage> createState() => _SetlistDetailPageState();
}

class _SetlistDetailPageState extends State<SetlistDetailPage> {
  late final SetlistDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SetlistDetailViewModel(
      repo: context.read(),
      setlistId: widget.setlistId,
    );
    _viewModel.addListener(_popIfDeleted);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_popIfDeleted);
    _viewModel.dispose();
    super.dispose();
  }

  void _popIfDeleted() {
    if (!_viewModel.deleted || !mounted) return;
    context.go("/");
  }

  Future<void> _rename() async {
    final setlist = _viewModel.setlist;
    if (setlist == null) return;
    final name = await SetlistNameDialog.show(
      context,
      title: "Rename setlist",
      confirmLabel: "Rename",
      initialName: setlist.name,
    );
    if (name == null) return;
    await _viewModel.rename(name);
  }

  Future<void> _addScores() async {
    final scoreIds = await AddScoresDialog.show(context);
    if (scoreIds == null || scoreIds.isEmpty) return;
    await _viewModel.addScores(scoreIds);
  }

  Widget _entryTile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final entry = _viewModel.entries[index];
    final score = entry.score;
    final greyed = !entry.playable;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: greyed ? theme.colorScheme.onSurfaceVariant : null,
    );

    final Widget leading;
    if (score == null) {
      leading = Container(
        width: SetlistDetailPage._thumbnailWidth.toDouble(),
        height: SetlistDetailPage._thumbnailHeight.toDouble(),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.music_off,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      leading = Opacity(
        opacity: greyed ? 0.5 : 1,
        child: Thumbnail(
          score: score,
          width: SetlistDetailPage._thumbnailWidth,
          height: SetlistDetailPage._thumbnailHeight,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return ListTile(
      key: ValueKey("${score?.id}-$index"),
      leading: leading,
      title: Text(
        score?.title ?? "Unavailable",
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      ),
      onTap: entry.playable
          ? () {
              context.go(
                "/setlists/${widget.setlistId}/play?startIndex=$index",
              );
            }
          : null,
      subtitle: Text(
        score == null
            ? "This score is not on this device"
            : score.file == null
            ? "Not downloaded yet"
            : score.composer ?? "No composer",
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Remove",
            onPressed: () => _viewModel.removeEntry(index),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final setlist = _viewModel.setlist;
        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: setlist == null ? null : _rename,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  setlist?.name ?? "",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _viewModel.entries.isEmpty
                      ? null
                      : () => context.go("/setlists/${widget.setlistId}/play"),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play"),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: setlist == null ? null : _addScores,
            icon: const Icon(Icons.add),
            label: const Text("Add scores"),
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (_viewModel.loading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (_viewModel.entries.isEmpty) {
                  return Center(
                    child: Text(
                      "This setlist is empty.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  buildDefaultDragHandles: false,
                  itemCount: _viewModel.entries.length,
                  itemBuilder: _entryTile,
                  onReorderItem: _viewModel.moveEntry,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
