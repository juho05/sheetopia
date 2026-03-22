/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/settings/appearance_viewmodel.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppearanceViewModel(
        settings: context.read<SettingsRepository>().appearanceSettings,
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Appearance")),
          body: SafeArea(
            child: Consumer<AppearanceViewModel>(
              builder: (context, viewModel, _) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownMenu<ThemeMode>(
                        onSelected: (mode) {
                          if (mode == null) return;
                          viewModel.updateMode(mode);
                        },
                        expandedInsets: EdgeInsets.zero,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        initialSelection: viewModel.mode,
                        label: const Text("Theme"),
                        dropdownMenuEntries: ThemeMode.values.map((mode) {
                          return DropdownMenuEntry<ThemeMode>(
                            label:
                                mode.name[0].toUpperCase() +
                                mode.name.substring(1),
                            value: mode,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
