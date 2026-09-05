/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/integrate_appimage.dart';
import 'package:sheetopia/ui/common/drop_area.dart';
import 'package:sheetopia/ui/common/fab_menu.dart';
import 'package:sheetopia/ui/common/selection/clear_selection_button.dart';
import 'package:sheetopia/ui/common/selection/select_all_button.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/bulk_edit/bulk_edit_menu.dart';
import 'package:sheetopia/ui/home/home_viewmodel.dart';
import 'package:sheetopia/ui/home/library_view.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';
import 'package:sheetopia/ui/home/sync_icon.dart';
import 'package:sheetopia/ui/practice/bulk_edit/routines_bulk_edit_menu.dart';
import 'package:sheetopia/ui/practice/practice_page.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';
import 'package:sheetopia/ui/setlists/bulk_edit/setlists_bulk_edit_menu.dart';
import 'package:sheetopia/ui/setlists/setlist_name_dialog.dart';
import 'package:sheetopia/ui/setlists/setlists_view.dart';
import 'package:sheetopia/ui/setlists/setlists_viewmodel.dart';
import 'package:sheetopia/version_checker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<({IconData icon, String label})> _tabs = [
    (icon: Symbols.library_music, label: "Library"),
    (icon: Symbols.queue_music, label: "Setlists"),
    (icon: Symbols.exercise, label: "Practice"),
  ];

  late final LibraryViewModel _libraryViewModel;
  late final SetlistsViewModel _setlistsViewModel;
  late final PracticeRoutinesViewModel _routinesViewModel;

  @override
  void initState() {
    super.initState();
    _libraryViewModel = LibraryViewModel(repo: context.read());
    _setlistsViewModel = SetlistsViewModel(repo: context.read());
    _routinesViewModel = PracticeRoutinesViewModel(
      repo: context.read(),
      scoresRepo: context.read(),
    );
  }

  @override
  void dispose() {
    _libraryViewModel.dispose();
    _setlistsViewModel.dispose();
    _routinesViewModel.dispose();
    super.dispose();
  }

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

  Future<void> _scanScore(BuildContext context) async {
    try {
      final firstScoreId = await context.read<HomeViewModel>().scanScore();
      if (!context.mounted || firstScoreId == null) {
        return;
      }
      context.go("/scores/$firstScoreId/edit");
    } catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Failed to scan score!");
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

  List<Widget> _selectionActions(HomeViewModel viewModel) {
    final selection = viewModel.selection;
    if (selection == null) return [];
    return switch (viewModel.tabIndex) {
      0 => [
        _SelectAllButton(
          selection: selection,
          viewModel: _libraryViewModel,
          resultCount: () => _libraryViewModel.resultCount,
          getAllIds: _libraryViewModel.getFilteredScoreIds,
        ),
        BulkEditMenu(
          selectedScoreIds: selection.ids,
          onDeleted: selection.clear,
        ),
      ],
      1 => [
        _SelectAllButton(
          selection: selection,
          viewModel: _setlistsViewModel,
          resultCount: () => _setlistsViewModel.resultCount,
          getAllIds: () async => _setlistsViewModel.loadedSetlistIds,
        ),
        SetlistsBulkEditMenu(
          selectedSetlistIds: selection.ids,
          onDeleted: selection.clear,
        ),
      ],
      2 => [
        _SelectAllButton(
          selection: selection,
          viewModel: _routinesViewModel,
          resultCount: () => _routinesViewModel.resultCount,
          getAllIds: _routinesViewModel.getFilteredRoutineIds,
        ),
        RoutinesBulkEditMenu(
          selectedRoutineIds: selection.ids,
          onDeleted: selection.clear,
        ),
      ],
      _ => [],
    };
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
            return Consumer<HomeViewModel>(
              builder: (context, viewModel, _) {
                return DropArea(
                  enabled: viewModel.tabIndex == 0,
                  onDrop: (files) async {
                    viewModel.tabIndex = 0;

                    try {
                      final firstScoreId = await viewModel.receiveDrop(files);
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
                      final rail =
                          constraints.maxWidth >= constraints.maxHeight;
                      return Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              final library = viewModel.tabIndex == 0;
                              final selecting = viewModel.selecting;
                              final scoreSelection = viewModel.scoreSelection;
                              final setlistSelection =
                                  viewModel.setlistSelection;
                              final routineSelection =
                                  viewModel.routineSelection;
                              final body = SafeArea(
                                child: IndexedStack(
                                  index: viewModel.tabIndex,
                                  children: [
                                    LibraryView(
                                      viewModel: _libraryViewModel,
                                      onScrollUp: () =>
                                          viewModel.importButtonVisible.value =
                                              true,
                                      onScrollDown: () =>
                                          viewModel.importButtonVisible.value =
                                              false,
                                      onScoreSelected: (score) =>
                                          scoreSelection.select(score.id),
                                      onScoreDeselected: (score) =>
                                          scoreSelection.deselect(score.id),
                                      onScoresSelected: (scoreIds) {
                                        if (viewModel.tabIndex != 0) return;
                                        scoreSelection.selectAll(scoreIds);
                                      },
                                      onClearSelection: scoreSelection.clear,
                                      selectionMode: scoreSelection.isNotEmpty,
                                      selected: scoreSelection.idSet,
                                    ),
                                    SetlistsView(
                                      viewModel: _setlistsViewModel,
                                      onSetlistSelected: (setlist) =>
                                          setlistSelection.select(setlist.id),
                                      onSetlistDeselected: (setlist) =>
                                          setlistSelection.deselect(setlist.id),
                                      onSetlistsSelected: (setlistIds) {
                                        if (viewModel.tabIndex != 1) return;
                                        setlistSelection.selectAll(setlistIds);
                                      },
                                      onClearSelection: setlistSelection.clear,
                                      selectionMode:
                                          setlistSelection.isNotEmpty,
                                      selected: setlistSelection.idSet,
                                    ),
                                    PracticePage(
                                      viewModel: _routinesViewModel,
                                      onRoutineSelected: (routine) =>
                                          routineSelection.select(routine.id),
                                      onRoutineDeselected: (routine) =>
                                          routineSelection.deselect(routine.id),
                                      onRoutinesSelected: (routineIds) {
                                        if (viewModel.tabIndex != 2) return;
                                        routineSelection.selectAll(routineIds);
                                      },
                                      onClearSelection: routineSelection.clear,
                                      selectionMode:
                                          routineSelection.isNotEmpty,
                                      selected: routineSelection.idSet,
                                    ),
                                  ],
                                ),
                              );
                              final importing = library && viewModel.importing;
                              return PopScope(
                                canPop: !selecting && library,
                                onPopInvokedWithResult: (didPop, _) {
                                  if (didPop) return;
                                  if (selecting) {
                                    viewModel.selection?.clear();
                                  } else {
                                    viewModel.tabIndex = 0;
                                  }
                                },
                                child: Scaffold(
                                  appBar: AppBar(
                                    centerTitle: false,
                                    leading:
                                        selecting && viewModel.selection != null
                                        ? ClearSelectionButton(
                                            onPressed:
                                                viewModel.selection!.clear,
                                          )
                                        : null,
                                    title: Text(
                                      selecting
                                          ? "${viewModel.selection?.length} selected"
                                          : _tabs[viewModel.tabIndex].label,
                                    ),
                                    actions: selecting
                                        ? _selectionActions(viewModel)
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
                                                icon: const Icon(
                                                  Icons.settings,
                                                ),
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
                                            labelType:
                                                NavigationRailLabelType.all,
                                            destinations: _tabs
                                                .map(
                                                  (t) =>
                                                      NavigationRailDestination(
                                                        icon: Icon(t.icon),
                                                        selectedIcon: Icon(
                                                          t.icon,
                                                          fill: 1,
                                                          grade: 200,
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
                                                    t.icon,
                                                    fill: 1,
                                                    grade: 200,
                                                  ),
                                                  label: t.label,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                  floatingActionButton: ValueListenableBuilder<bool>(
                                    valueListenable:
                                        viewModel.importButtonVisible,
                                    builder:
                                        (context, importButtonVisible, child) {
                                          final fabVisible =
                                              !library || importButtonVisible;
                                          return AnimatedSlide(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
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
                                    child: importing
                                        ? FloatingActionButton(
                                            onPressed: null,
                                            backgroundColor: disabledColor,
                                            tooltip: "Import score",
                                            child: const Padding(
                                              padding: EdgeInsets.all(16),
                                              child:
                                                  CircularProgressIndicator.adaptive(),
                                            ),
                                          )
                                        : FabMenu(
                                            tooltip:
                                                switch (viewModel.tabIndex) {
                                                  0 => "Import score",
                                                  1 => "Create setlist",
                                                  2 => "Create routine",
                                                  _ => "",
                                                },
                                            icon: const Icon(Icons.add),
                                            items: switch (viewModel.tabIndex) {
                                              0 => [
                                                if (Platform.isAndroid ||
                                                    Platform.isIOS)
                                                  FabMenuItem(
                                                    icon:
                                                        Icons.document_scanner,
                                                    label: "Scan pages",
                                                    onPressed: () =>
                                                        _scanScore(context),
                                                  ),
                                                FabMenuItem(
                                                  icon: Icons.file_open,
                                                  label: "Import files",
                                                  onPressed: () =>
                                                      _importScores(context),
                                                ),
                                              ],
                                              1 => [
                                                FabMenuItem(
                                                  label: "Create setlist",
                                                  onPressed: () =>
                                                      _createSetlist(context),
                                                ),
                                              ],
                                              2 => [
                                                FabMenuItem(
                                                  label:
                                                      "Create practice routine",
                                                  onPressed: () => context.go(
                                                    "/practice/routines/create",
                                                  ),
                                                ),
                                              ],
                                              _ => [],
                                            },
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
            );
          },
        ),
      ),
    );
  }
}

class _SelectAllButton extends StatelessWidget {
  final SelectionModel selection;
  final Listenable viewModel;
  final int? Function() resultCount;
  final Future<List<String>> Function() getAllIds;

  const _SelectAllButton({
    required this.selection,
    required this.viewModel,
    required this.resultCount,
    required this.getAllIds,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => SelectAllButton(
        resultCount: resultCount(),
        selectedCount: selection.length,
        onSelectAll: () async => selection.selectAll(await getAllIds()),
        onClearSelection: selection.clear,
      ),
    );
  }
}
