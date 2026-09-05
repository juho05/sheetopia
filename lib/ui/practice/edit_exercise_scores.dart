/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/drop_area.dart';
import 'package:sheetopia/ui/common/import_source_dialog.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/thumbnail.dart';
import 'package:sheetopia/ui/practice/edit_exercise_viewmodel.dart';
import 'package:sheetopia/ui/setlists/add_scores_dialog.dart';
import 'package:sheetopia/utils/score_file.dart';

class EditExerciseScores extends StatelessWidget {
  const EditExerciseScores({super.key});

  Future<void> _linkScores(
    BuildContext context,
    EditExerciseViewModel viewModel,
  ) async {
    final scoreIds = await AddScoresDialog.show(context);
    if (scoreIds == null || scoreIds.isEmpty) return;
    await viewModel.linkScores(scoreIds);
  }

  Future<void> _addScores(
    BuildContext context,
    EditExerciseViewModel viewModel,
  ) async {
    final source = await ImportSourceDialog.show(context);
    switch (source) {
      case null:
        return;
      case ImportSource.file:
        await _import(() => viewModel.importScores());
      case ImportSource.scan:
        await _scan(viewModel);
    }
  }

  Future<void> _scan(EditExerciseViewModel viewModel) async {
    try {
      await viewModel.scanScores();
    } catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Failed to scan score!");
    }
  }

  Future<void> _receiveDrop(
    EditExerciseViewModel viewModel,
    List<XFile> files,
  ) async {
    await _import(() => viewModel.receiveDrop(files));
  }

  Future<void> _import(Future<void> Function() action) async {
    try {
      await action();
    } on InvalidFileTypeException catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
    } catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Failed to import files!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditExerciseViewModel>(
      builder: (context, viewModel, _) {
        return DropArea(
          onDrop: (files) => _receiveDrop(viewModel, files),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverReorderableList(
                  itemCount: viewModel.scoreEntries.length,
                  itemBuilder: (context, index) => _ScoreListItem(
                    key: ValueKey(viewModel.scoreEntries[index].id),
                    viewModel: viewModel,
                    entry: viewModel.scoreEntries[index],
                    index: index,
                  ),
                  onReorderItem: viewModel.moveScore,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _AddScorePlaceholder(
                    onAdd: () => _addScores(context, viewModel),
                    onLink: () => _linkScores(context, viewModel),
                    loading: viewModel.scoresLoading,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreListItem extends StatefulWidget {
  final EditExerciseViewModel viewModel;
  final ExerciseScoreEntry entry;
  final int index;

  const _ScoreListItem({
    super.key,
    required this.entry,
    required this.index,
    required this.viewModel,
  });

  @override
  State<_ScoreListItem> createState() => _ScoreListItemState();
}

class _ScoreListItemState extends State<_ScoreListItem> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.entry.score.title,
  );

  late bool _titleEmpty = widget.entry.score.title.trim().isEmpty;

  final _titleFocus = FocusNode();

  @override
  void didUpdateWidget(covariant _ScoreListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.score.title != widget.entry.score.title &&
        widget.entry.score.title != _titleController.text) {
      _titleController.text = widget.entry.score.title;
      final empty = widget.entry.score.title.trim().isEmpty;
      if (empty != _titleEmpty) {
        setState(() => _titleEmpty = empty);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbnailWidth = constraints.maxWidth >= 400 ? 110 : 90;
        final thumbnailHeight = 140;
        return ReorderableDelayedDragStartListener(
          index: widget.index,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: thumbnailHeight.toDouble(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReorderableDragStartListener(
                        index: widget.index,
                        child: Material(
                          color: theme.colorScheme.surfaceContainer,
                          child: SizedBox(
                            width: 40,
                            height: thumbnailHeight.toDouble(),
                            child: Icon(
                              Symbols.drag_indicator,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Thumbnail(
                        score: widget.entry.score,
                        width: thumbnailWidth,
                        height: thumbnailHeight,
                        devicePixelRatio: dpi,
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: thumbnailHeight.toDouble(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 8,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child:
                                          widget.entry.score.type ==
                                              ScoreType.exercise
                                          ? TextField(
                                              controller: _titleController,
                                              focusNode: _titleFocus,
                                              onTapOutside: (event) =>
                                                  _titleFocus.unfocus(),
                                              onChanged: (value) {
                                                final empty = value
                                                    .trim()
                                                    .isEmpty;
                                                if (!empty) {
                                                  widget.viewModel
                                                      .setScoreTitle(
                                                        widget.entry.score.id,
                                                        value,
                                                      );
                                                }
                                                if (empty == _titleEmpty) {
                                                  return;
                                                }
                                                setState(
                                                  () => _titleEmpty = empty,
                                                );
                                              },
                                              decoration: InputDecoration(
                                                label: const Text("Title"),
                                                border:
                                                    const OutlineInputBorder(),
                                                errorText: _titleEmpty
                                                    ? "Title is required"
                                                    : null,
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    spacing: 4,
                                                    children: [
                                                      Icon(
                                                        Symbols.link,
                                                        size: 14,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                      Text(
                                                        "Linked score",
                                                        style: theme
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    widget.entry.score.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _ScoreFileMenu(
                                        viewModel: widget.viewModel,
                                        score: widget.entry.score,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Align(
                                  alignment: AlignmentGeometry.bottomRight,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      Button(
                                        child: const Text("View"),
                                        onPressed: () {
                                          context.go(
                                            "/practice/exercises/${widget.viewModel.exerciseId ?? "create"}/scores/${widget.entry.score.id}",
                                          );
                                        },
                                      ),
                                      Button(
                                        color: theme.colorScheme.errorContainer,
                                        textColor:
                                            theme.colorScheme.onErrorContainer,
                                        onPressed: () async {
                                          final confirmation =
                                              await ConfirmationDialog.showYesNo(
                                                context,
                                                title:
                                                    widget.entry.score.type ==
                                                        ScoreType.exercise
                                                    ? "Delete score?"
                                                    : "Unlink score?",
                                                message:
                                                    widget.entry.score.type ==
                                                        ScoreType.exercise
                                                    ? "The score will be deleted!"
                                                    : "The score will be unlinked from this exercise.",
                                              );
                                          if (confirmation != true) return;
                                          await widget.viewModel.removeScore(
                                            widget.entry.id,
                                          );
                                        },
                                        child:
                                            widget.entry.score.type ==
                                                ScoreType.exercise
                                            ? const Text("Delete")
                                            : const Text("Unlink"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreFileMenu extends StatelessWidget {
  final EditExerciseViewModel viewModel;
  final Score score;

  const _ScoreFileMenu({required this.viewModel, required this.score});

  Future<void> _share(BuildContext context) async {
    Rect? sharePositionOrigin;
    if (Platform.isIOS) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    await shareScoreFile(score, sharePositionOrigin: sharePositionOrigin);
  }

  Future<void> _export() async {
    if (!await exportScoreFile(score)) return;
    Toast.show("Successfully saved score file!");
  }

  Future<void> _changeFile() async {
    try {
      await viewModel.changeScoreFile(score.id);
    } on InvalidFileTypeException catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
    } catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Failed to change score file!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Platform.isAndroid || Platform.isIOS;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MenuButton(
        tooltip: "Score file actions",
        options: [
          if (mobile)
            ContextMenuOption(
              icon: Icons.share,
              title: "Share",
              onSelected: () => _share(context),
            ),
          if (!Platform.isIOS)
            ContextMenuOption(
              icon: Icons.save_alt,
              title: "Export",
              onSelected: _export,
            ),
          ContextMenuOption(
            icon: Icons.edit,
            title: "Change file",
            onSelected: _changeFile,
          ),
        ],
      ),
    );
  }
}

class _AddScorePlaceholder extends StatelessWidget {
  final void Function() onAdd;
  final void Function() onLink;
  final bool loading;

  const _AddScorePlaceholder({
    required this.onAdd,
    required this.onLink,
    this.loading = false,
  });

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
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        spacing: 12,
                        children: [
                          Expanded(
                            child: Button(
                              onPressed: onAdd,
                              icon: Symbols.upload_file,
                              darkTonal: true,
                              child: constraints.maxWidth >= 375
                                  ? const Text("Import score")
                                  : const Text("Import"),
                            ),
                          ),
                          Text(
                            "OR",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Button(
                              onPressed: onLink,
                              icon: Symbols.link,
                              darkTonal: true,
                              child: constraints.maxWidth >= 375
                                  ? const Text("Link score")
                                  : const Text("Link"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
