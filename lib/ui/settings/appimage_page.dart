/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/services/restart/restart.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/settings/appimage_settings_viewmodel.dart';

class AppImagePage extends StatelessWidget {
  const AppImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    return ChangeNotifierProvider(
      create: (context) =>
          AppImageSettingsViewModel(appImageRepository: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("AppImage Integration")),
          body: SafeArea(
            child: Consumer<AppImageSettingsViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    Row(
                      children: [
                        const Text("Integrated: "),
                        Text(
                          viewModel.integrated == null
                              ? "checking…"
                              : (viewModel.integrated! ? "YES" : "NO"),
                          style: viewModel.integrated != null
                              ? textStyle.copyWith(
                                  color: viewModel.integrated!
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        onPressed: viewModel.integrated != null
                            ? () async {
                                try {
                                  await viewModel.integrate();
                                  Restart.restart();
                                } catch (e, st) {
                                  Toast.show("Failed to integrate AppImage!");
                                  Log.error(
                                    "Failed to integrate AppImage!",
                                    e: e,
                                    st: st,
                                  );
                                }
                              }
                            : null,
                        icon: Icons.install_desktop,
                        outlined: viewModel.integrated ?? false,
                        child: Text(
                          (viewModel.integrated ?? false)
                              ? "Re-Integrate"
                              : "Integrate",
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Integrating the Sheetopia AppImage will move it to ~/.local/bin/sheetopia and create a .desktop file "
                      "to make it appear in app launchers and to give it a window icon on Wayland.",
                      style: textStyle.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        fontSize: 12,
                      ),
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
