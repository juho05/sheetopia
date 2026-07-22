/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/auto_update/auto_update_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/common/adaptive_dialog_action.dart';
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/settings/version_checking_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

enum VersionCheckNowDialogOptions { close, view, install }

class VersionCheckingPage extends StatelessWidget {
  const VersionCheckingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    return ChangeNotifierProvider(
      create: (context) => VersionCheckingViewModel(
        settings: context.read<SettingsRepository>().versionChecking,
        repository: context.read(),
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Version Checking")),
          body: SafeArea(
            child: Consumer<VersionCheckingViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    SwitchListTile(
                      onChanged: (value) {
                        viewModel.updateEnabled(value);
                      },
                      value: viewModel.enabled,
                      title: const Text("Check for new versions"),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        enabled: !viewModel.checking,
                        onPressed: () async {
                          try {
                            final result = await viewModel.check();
                            if (!context.mounted) return;
                            final current = result.current;
                            final latest = result.latest;
                            if (latest == null) return;
                            if (latest > current) {
                              final actions = [
                                AdaptiveDialogAction(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    VersionCheckNowDialogOptions.view,
                                  ),
                                  child: const Text("View"),
                                ),
                                if (AutoUpdateRepository.autoUpdatesSupported)
                                  AdaptiveDialogAction(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      VersionCheckNowDialogOptions.install,
                                    ),
                                    child: const Text("Install"),
                                  ),
                                AdaptiveDialogAction(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    VersionCheckNowDialogOptions.close,
                                  ),
                                  child: const Text("Close"),
                                ),
                              ];
                              showAdaptiveDialog<VersionCheckNowDialogOptions>(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  return AlertDialog.adaptive(
                                    title: const Text("New version available"),
                                    content: Text(
                                      "Current: v$current\nLatest: v$latest",
                                    ),
                                    actions: actions,
                                  );
                                },
                              ).then((choice) async {
                                if (!context.mounted) return;
                                switch (choice) {
                                  case VersionCheckNowDialogOptions.close ||
                                      null:
                                    break;
                                  case VersionCheckNowDialogOptions.view:
                                    launchUrl(
                                      Uri.https(
                                        "github.com",
                                        "/juho05/sheetopia/releases",
                                      ),
                                    );
                                  case VersionCheckNowDialogOptions.install:
                                    context.go("/installUpdate");
                                }
                              });
                            } else {
                              Toast.show(
                                "You are already running the latest version: v$current!",
                              );
                            }
                          } catch (e, st) {
                            Toast.show("Failed to fetch latest version!");
                            Log.error(
                              "Failed to fetch latest version!",
                              e: e,
                              st: st,
                            );
                          }
                        },
                        icon: Icons.update,
                        darkTonal: true,
                        child: viewModel.checking
                            ? const Text("Checking…")
                            : const Text("Check now"),
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
                      "Enabling version checking will periodically contact the GitHub API to check for new versions of Sheetopia "
                      "and display a dialog on startup if a new version is found.",
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
