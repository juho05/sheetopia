/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/settings/page_turning_viewmodel.dart';

class PageTurningPage extends StatelessWidget {
  const PageTurningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PageTurningViewModel(
        settings: context.read<SettingsRepository>().pageTurning,
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Page Turning")),
          body: SafeArea(
            child: Consumer<PageTurningViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  children: [
                    ListTile(
                      title: const Text("MIDI Devices"),
                      trailing: const Icon(Icons.arrow_forward_ios_outlined),
                      onTap: () {
                        context.go("/settings/pageTurning/midi");
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Flash on page turn"),
                      value: viewModel.flashOnPageTurn,
                      onChanged: viewModel.updateFlashOnPageTurn,
                    ),
                    SwitchListTile(
                      title: const Text("Gradual page turns"),
                      subtitle: const Text(
                        "Turn half a page at a time or a single page if "
                        "several fit on screen",
                      ),
                      value: viewModel.gradualPageTurns,
                      onChanged: viewModel.updateGradualPageTurns,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
