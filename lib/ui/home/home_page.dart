/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/integrate_appimage.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/home_viewmodel.dart';
import 'package:sheetopia/ui/home/library_view.dart';
import 'package:sheetopia/ui/home/sync_icon.dart';
import 'package:sheetopia/version_checker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = Color.fromARGB(
      255,
      theme.brightness == Brightness.light ? 227 : 46,
      theme.brightness == Brightness.light ? 220 : 43,
      theme.brightness == Brightness.light ? 228 : 48,
    );
    return VersionChecker(
      child: IntegrateAppImage(
        child: ChangeNotifierProvider(
          create: (context) => HomeViewModel(scoresRepo: context.read()),
          builder: (context, _) {
            final viewModel = context.read<HomeViewModel>();
            return DropTarget(
              onDragEntered: (_) => viewModel.dragging = true,
              onDragExited: (_) => viewModel.dragging = false,
              onDragDone: (details) async {
                viewModel.dragging = false;

                try {
                  final firstScoreId = await viewModel.receiveDrop(details);
                  if (!context.mounted) {
                    return;
                  }
                  context.go("/scores/$firstScoreId/edit");
                } on InvalidFileTypeException catch (e, st) {
                  Toast.exception(
                    context,
                    e,
                    st: st,
                    errorMsg: "Unsupported file type!",
                  );
                } catch (e, st) {
                  Toast.exception(
                    context,
                    e,
                    st: st,
                    errorMsg: "Failed to import scores!",
                  );
                }
              },
              child: Stack(
                children: [
                  Scaffold(
                    appBar: AppBar(
                      title: const Text("Library"),
                      actions: [
                        const SyncIcon(),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            onPressed: () {
                              context.go("/settings");
                            },
                            icon: const Icon(Icons.settings),
                          ),
                        ),
                      ],
                    ),
                    body: SafeArea(
                      child: LibraryView(
                        onScrollUp: () => viewModel.importButtonVisible = true,
                        onScrollDown: () =>
                            viewModel.importButtonVisible = false,
                      ),
                    ),
                    floatingActionButton: Consumer<HomeViewModel>(
                      builder: (context, viewModel, _) {
                        final duration = const Duration(milliseconds: 200);
                        return AnimatedSlide(
                          duration: duration,
                          offset: viewModel.importButtonVisible
                              ? Offset.zero
                              : const Offset(0, 2),
                          child: AnimatedOpacity(
                            duration: duration,
                            opacity: viewModel.importButtonVisible ? 1 : 0,
                            child: FloatingActionButton(
                              onPressed: viewModel.importing
                                  ? null
                                  : () async {
                                      try {
                                        final firstScoreId = await context
                                            .read<HomeViewModel>()
                                            .importScores();
                                        if (!context.mounted ||
                                            firstScoreId == null) {
                                          return;
                                        }
                                        context.go(
                                          "/scores/$firstScoreId/edit",
                                        );
                                      } on InvalidFileTypeException catch (
                                        e,
                                        st
                                      ) {
                                        Toast.exception(
                                          context,
                                          e,
                                          st: st,
                                          errorMsg: "Unsupported file type!",
                                        );
                                      } catch (e, st) {
                                        Toast.exception(
                                          context,
                                          e,
                                          st: st,
                                          errorMsg: "Failed to import scores!",
                                        );
                                      }
                                    },
                              backgroundColor: viewModel.importing
                                  ? disabledColor
                                  : null,
                              tooltip: "Import score",
                              child: viewModel.importing
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    )
                                  : const Icon(Icons.add),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Consumer<HomeViewModel>(
                    builder: (context, viewModel, _) {
                      final labelColor = theme.brightness == Brightness.dark
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onPrimary;
                      return IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: viewModel.dragging ? 1 : 0,
                          child: Container(
                            color: theme.colorScheme.scrim.withValues(
                              alpha: 0.8,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.file_download_outlined,
                                    size: 96,
                                    color: labelColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Drop to import",
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(color: labelColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
