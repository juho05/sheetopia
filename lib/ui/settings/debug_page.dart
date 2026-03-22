/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/section_header.dart';
import 'package:sheetopia/ui/settings/debug_viewmodel.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late final DebugViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DebugViewModel(settings: context.read());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SectionHeader(text: "Logging"),
              ),
              DropdownMenu<Level>(
                onSelected: (level) {
                  if (level == null) return;
                  _viewModel.level = level;
                },
                expandedInsets: EdgeInsets.zero,
                requestFocusOnTap: false,
                enableSearch: false,
                initialSelection: _viewModel.level,
                label: const Text("Level"),
                dropdownMenuEntries: [
                  const DropdownMenuEntry<Level>(
                    label: "OFF",
                    value: Level.off,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Fatal",
                    value: Level.fatal,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Error",
                    value: Level.error,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Warning",
                    value: Level.warning,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Info",
                    value: Level.info,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Debug",
                    value: Level.debug,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Trace",
                    value: Level.trace,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Button(
                    onPressed: () {
                      context.go("/settings/debug/logs");
                    },
                    darkTonal: true,
                    icon: Icons.list,
                    child: const Text("View logs"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
