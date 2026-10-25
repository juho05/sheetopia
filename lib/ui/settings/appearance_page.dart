/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/appearance.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/common/heading.dart';
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
                return SingleChildScrollView(
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
                      const Heading(
                        text: "Library cards",
                        padding: EdgeInsets.only(top: 8),
                      ),
                      DropdownMenu<CardSubtitle>(
                        onSelected: (value) {
                          if (value == null) return;
                          viewModel.updateCardSubtitle(value);
                        },
                        expandedInsets: EdgeInsets.zero,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        initialSelection: viewModel.cardSubtitle,
                        label: const Text("Subtitle"),
                        dropdownMenuEntries: [
                          for (final value in CardSubtitle.values)
                            DropdownMenuEntry(value: value, label: value.label),
                        ],
                      ),
                      DropdownMenu<CardBadges>(
                        onSelected: (value) {
                          if (value == null) return;
                          viewModel.updateCardBadges(value);
                        },
                        expandedInsets: EdgeInsets.zero,
                        requestFocusOnTap: false,
                        enableSearch: false,
                        initialSelection: viewModel.cardBadges,
                        label: const Text("Badges"),
                        dropdownMenuEntries: [
                          for (final value in CardBadges.values)
                            DropdownMenuEntry(value: value, label: value.label),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Show difficulty"),
                        subtitle: const Text(
                          "On library cards and exercise lists",
                        ),
                        value: viewModel.cardDifficulty,
                        onChanged: viewModel.updateCardDifficulty,
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
