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
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/integrate_appimage.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/bulk_edit/bulk_edit_menu.dart';
import 'package:sheetopia/ui/home/home_viewmodel.dart';
import 'package:sheetopia/ui/home/library_view.dart';
import 'package:sheetopia/ui/home/sync_icon.dart';
import 'package:sheetopia/ui/setlists/setlist_name_dialog.dart';
import 'package:sheetopia/ui/setlists/setlists_view.dart';
import 'package:sheetopia/version_checker.dart';

class HomePage extends StatelessWidget {
  static const List<({IconData icon, IconData selectedIcon, String label})>
  _tabs = [
    (
      icon: Icons.library_music_outlined,
      selectedIcon: Icons.library_music,
      label: "Library",
    ),
    (
      icon: Icons.queue_music_outlined,
      selectedIcon: Icons.queue_music,
      label: "Setlists",
    ),
  ];

  const HomePage({super.key});

  Future<void> _importScores(BuildContext context) async {
    try {
      final firstScoreId = await context.read<HomeViewModel>().importScores();
      if (!context.mounted || firstScoreId == null) {
        return;
      }
      context.go("/scores/$firstScoreId/edit");
    } on InvalidFileTypeException catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
    } catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Failed to import scores!");
    }
  }

  Future<void> _createSetlist(BuildContext context) async {
    final repo = context.read<SetlistsRepository>();
    final name = await SetlistNameDialog.show(
      context,
      title: "New setlist",
      confirmLabel: "Create",
    );
    if (name == null) return;
    await repo.createSetlist(name: name);
  }

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
                viewModel.tabIndex = 0;

                try {
                  final firstScoreId = await viewModel.receiveDrop(details);
                  if (!context.mounted) {
                    return;
                  }
                  context.go("/scores/$firstScoreId/edit");
                } on InvalidFileTypeException catch (e, st) {
                  Toast.exception(
                    e,
                    st: st,
                    errorMsg: "Unsupported file type!",
                  );
                } catch (e, st) {
                  Toast.exception(
                    e,
                    st: st,
                    errorMsg: "Failed to import scores!",
                  );
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rail = constraints.maxWidth >= constraints.maxHeight;
                  return Stack(
                    children: [
                      Consumer<HomeViewModel>(
                        builder: (context, viewModel, _) {
                          final library = viewModel.tabIndex == 0;
                          final body = SafeArea(
                            child: IndexedStack(
                              index: viewModel.tabIndex,
                              children: [
                                LibraryView(
                                  onScrollUp: () =>
                                      viewModel.importButtonVisible.value =
                                          true,
                                  onScrollDown: () =>
                                      viewModel.importButtonVisible.value =
                                          false,
                                  onScoreSelected: (score) {
                                    viewModel.selectScore(score.id);
                                  },
                                  onScoreDeselected: (score) {
                                    viewModel.deselectScore(score.id);
                                  },
                                  selectionMode:
                                      viewModel.selectedScoreIds.isNotEmpty,
                                  selected: viewModel.selectedScoreIdSet,
                                ),
                                const SetlistsView(),
                              ],
                            ),
                          );
                          final importing = library && viewModel.importing;
                          bool selectionMode =
                              viewModel.tabIndex == 0 &&
                              viewModel.selectedScoreIds.isNotEmpty;
                          return PopScope(
                            canPop: !selectionMode && library,
                            onPopInvokedWithResult: (didPop, _) {
                              if (didPop) return;
                              if (selectionMode) {
                                viewModel.clearSelection();
                              } else {
                                viewModel.tabIndex = 0;
                              }
                            },
                            child: Scaffold(
                              appBar: AppBar(
                                title: selectionMode
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              viewModel.clearSelection();
                                            },
                                            icon: const Icon(Icons.close),
                                          ),
                                          Text(
                                            "${viewModel.selectedScoreIds.length} selected",
                                          ),
                                        ],
                                      )
                                    : Text(_tabs[viewModel.tabIndex].label),
                                actions: selectionMode
                                    ? [
                                        BulkEditMenu(
                                          selectedScoreIds:
                                              viewModel.selectedScoreIds,
                                        ),
                                      ]
                                    : [
                                        const SyncIcon(),
                                        const SizedBox(width: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              context.go("/settings");
                                            },
                                            icon: const Icon(Icons.settings),
                                          ),
                                        ),
                                      ],
                              ),
                              body: Row(
                                children: [
                                  if (rail)
                                    SafeArea(
                                      child: NavigationRail(
                                        selectedIndex: viewModel.tabIndex,
                                        onDestinationSelected: (index) =>
                                            viewModel.tabIndex = index,
                                        labelType: NavigationRailLabelType.all,
                                        destinations: _tabs
                                            .map(
                                              (t) => NavigationRailDestination(
                                                icon: Icon(t.icon),
                                                selectedIcon: Icon(
                                                  t.selectedIcon,
                                                ),
                                                label: Text(t.label),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  Expanded(child: body),
                                ],
                              ),
                              bottomNavigationBar: rail
                                  ? null
                                  : NavigationBar(
                                      selectedIndex: viewModel.tabIndex,
                                      onDestinationSelected: (index) =>
                                          viewModel.tabIndex = index,
                                      destinations: _tabs
                                          .map(
                                            (t) => NavigationDestination(
                                              icon: Icon(t.icon),
                                              selectedIcon: Icon(
                                                t.selectedIcon,
                                              ),
                                              label: t.label,
                                            ),
                                          )
                                          .toList(),
                                    ),
                              floatingActionButton: ValueListenableBuilder<bool>(
                                valueListenable: viewModel.importButtonVisible,
                                builder: (context, importButtonVisible, child) {
                                  final fabVisible =
                                      !library || importButtonVisible;
                                  return AnimatedSlide(
                                    duration: const Duration(milliseconds: 200),
                                    offset: fabVisible
                                        ? Offset.zero
                                        : const Offset(0, 2),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: fabVisible ? 1 : 0,
                                      child: child,
                                    ),
                                  );
                                },
                                child: FloatingActionButton(
                                  onPressed: importing
                                      ? null
                                      : () => library
                                            ? _importScores(context)
                                            : _createSetlist(context),
                                  backgroundColor: importing
                                      ? disabledColor
                                      : null,
                                  tooltip: library
                                      ? "Import score"
                                      : "New setlist",
                                  child: importing
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child:
                                              CircularProgressIndicator.adaptive(),
                                        )
                                      : const Icon(Icons.add),
                                ),
                              ),
                            ),
                          );
                        },
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
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
