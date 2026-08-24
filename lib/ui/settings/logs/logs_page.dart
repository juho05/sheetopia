/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/ui/common/menu_button.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/settings/logs/log_message_list_item.dart';
import 'package:sheetopia/ui/settings/logs/logs_page_viewmodel.dart';
import 'package:sheetopia/utils/format.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();

  late final LogsPageViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LogsPageViewModel(
      settingsRepository: context.read(),
      logRepository: context.read(),
    );

    _scrollController.addListener(() {
      _viewModel.enableMessageStream(_scrollController.position.pixels < 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shareButton =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs"),
        actions: [
          // the Android share dialog does not allow saving the file
          if (!shareButton || (!kIsWeb && Platform.isAndroid))
            MenuButton(
              icon: const Icon(Icons.save_alt),
              tooltip: "Save log",
              options: [
                ContextMenuOption(
                  title: "Save full log",
                  onSelected: () async {
                    final result = await _viewModel.saveLog(filtered: false);
                    if (!context.mounted) return;
                    if (!result) {
                      // user canceled save
                      return;
                    }
                    Toast.show("Successfully saved log!");
                  },
                ),
                ContextMenuOption(
                  title: "Save filtered log",
                  onSelected: () async {
                    final result = await _viewModel.saveLog(filtered: true);
                    if (!context.mounted) return;
                    if (!result) {
                      // user canceled save
                      return;
                    }
                    Toast.show("Successfully saved log!");
                  },
                ),
              ],
            ),
          if (shareButton)
            Builder(
              builder: (context) {
                Rect? sharePositionOrigin() {
                  if (Platform.isIOS) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      return box.localToGlobal(Offset.zero) & box.size;
                    }
                  }
                  return null;
                }

                return MenuButton(
                  icon: const Icon(Icons.share),
                  tooltip: "Share log",
                  options: [
                    ContextMenuOption(
                      title: "Share full log",
                      onSelected: () async {
                        final result = await _viewModel.shareLog(
                          filtered: false,
                          sharePositionOrigin: sharePositionOrigin(),
                        );
                        if (!context.mounted) return;
                        if (!result) {
                          // user canceled share
                          return;
                        }
                        Toast.show("Successfully shared log!");
                      },
                    ),
                    ContextMenuOption(
                      title: "Share filtered log",
                      onSelected: () async {
                        final result = await _viewModel.shareLog(
                          filtered: true,
                          sharePositionOrigin: sharePositionOrigin(),
                        );
                        if (!context.mounted) return;
                        if (!result) {
                          // user canceled share
                          return;
                        }
                        Toast.show("Successfully shared log!");
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverList.list(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Text(
                            "Session:",
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _viewModel.sessionTime == Log.sessionStartTime
                                ? "Current"
                                : formatDateTime(_viewModel.sessionTime),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final chosenSession = await context.push<DateTime>(
                          "/settings/debug/logs/session",
                          extra: _viewModel.sessionTime,
                        );
                        if (chosenSession == null) return;
                        await _viewModel.changeSessionTime(chosenSession);
                        _scrollController.jumpTo(0);
                      },
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverToBoxAdapter(
                    child: SearchInput(
                      onSearch: _viewModel.search,
                      debounce: const Duration(milliseconds: 250),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortNames = constraints.maxWidth < 640;
                        return SegmentedButton(
                          emptySelectionAllowed: true,
                          multiSelectionEnabled: true,
                          showSelectedIcon: constraints.maxWidth > 325,
                          onSelectionChanged: (levels) {
                            _viewModel.enabledLevels = levels;
                          },
                          segments: <ButtonSegment<Level>>[
                            ButtonSegment(
                              value: Level.trace,
                              label: Text(shortNames ? "T" : "Trace"),
                              tooltip: "Show trace",
                            ),
                            ButtonSegment(
                              value: Level.debug,
                              label: Text(shortNames ? "D" : "Debug"),
                              tooltip: "Show debug",
                            ),
                            ButtonSegment(
                              value: Level.info,
                              label: Text(shortNames ? "I" : "Info"),
                              tooltip: "Show info",
                            ),
                            ButtonSegment(
                              value: Level.warning,
                              label: Text(shortNames ? "W" : "Warning"),
                              tooltip: "Show warnings",
                            ),
                            ButtonSegment(
                              value: Level.error,
                              label: Text(shortNames ? "E" : "Error"),
                              tooltip: "Show errors",
                            ),
                            ButtonSegment(
                              value: Level.fatal,
                              label: Text(shortNames ? "F" : "Fatal"),
                              tooltip: "Show fatal",
                            ),
                          ],
                          selected: _viewModel.enabledLevels,
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8.0),
                  sliver: SliverFixedExtentList.builder(
                    itemBuilder: (context, index) => LogMessageListItem(
                      msg:
                          _viewModel.logMessages[_viewModel.logMessages.length -
                              1 -
                              index],
                    ),
                    itemExtent: LogMessageListItem.verticalExtent,
                    itemCount: _viewModel.logMessages.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
