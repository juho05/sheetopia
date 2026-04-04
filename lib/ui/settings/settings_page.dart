/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text("MIDI Devices"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/midi");
              },
            ),
            ListTile(
              title: const Text("Appearance"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/appearance");
              },
            ),
            ListTile(
              title: const Text("Import/Export"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/importExport");
              },
            ),
            ListTile(
              title: const Text("Debug"),
              trailing: const Icon(Icons.arrow_forward_ios_outlined),
              onTap: () {
                context.go("/settings/debug");
              },
            ),
            ListTile(
              title: const Text("About"),
              trailing: const Icon(Icons.info_outline),
              onTap: () async {
                final version =
                    "v${await VersionRepository.getCurrentVersion()}";
                if (!context.mounted) return;
                showAboutDialog(
                  context: context,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Image.asset(
                        "assets/icon/sheetopia-circle.png",
                        cacheHeight: 48 * 2,
                        cacheWidth: 48 * 2,
                        isAntiAlias: true,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  applicationName: "Sheetopia",
                  applicationVersion: version,
                  applicationLegalese:
                      "\u{a9} 2025-${DateTime.now().year} Julian Hofmann",
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      "Sheetopia is a cross-platform sheet music library manager.\n"
                      "It's free software under the MPL-2.0 license.",
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse("https://github.com/juho05/sheetopia"),
                        ),
                        child: Text("GitHub", style: linkStyle),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
