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
import 'package:sheetopia/ui/common/buttons.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/settings/importexport_viewmodel.dart';

class ImportExportPage extends StatelessWidget {
  const ImportExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Provider(
      create: (context) => ImportExportViewModel(syncRepo: context.read(), scoresRepo: context.read()),
      builder: (context, _) {
        final viewModel = context.read<ImportExportViewModel>();
        return Scaffold(
          appBar: AppBar(
            title: const Text("Import/Export"),
          ),
          body: SafeArea(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Heading(text: "Import"),
              ),
              Align(
                alignment: AlignmentGeometry.centerLeft,
                child: Button(
                  onPressed: () {
                    // TODO
                  },
                  child: const Text("Import .zip"),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Heading(text: "Export"),
              ),
              // TODO improve feedback during export
              Align(
                alignment: AlignmentGeometry.centerLeft,
                child: Button(
                  onPressed: () async {
                    Toast.show(context, "Exporting…");
                    try {
                      final success = await viewModel.export();
                      if (!success || !context.mounted) return;
                      Toast.show(context, "Export successful!");
                    } on Exception catch (e, st) {
                      Log.error("Export failed", e: e, st: st);
                      if (!context.mounted) return;
                      Toast.show(context, "Export failed!");
                    }
                  },
                  child: const Text("Export .zip"),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Heading(text: "Reset"),
              ),
              Align(
                alignment: AlignmentGeometry.centerLeft,
                child: Button(
                  style:FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.showYesNo(context, message: "Sync will be disabled and all local scores, tags, etc. will be deleted.\n\nRemote data will not be deleted.");
                    if (confirmed != true) return;

                    // TODO ask whether to delete remote data if logged in

                    try {
                      await viewModel.deleteLocalData();
                      if (!context.mounted) return;
                      Toast.show(context, "Successfully deleted all local data!");
                    } on Exception catch (e, st) {
                      Log.error("Failed to delete local data", e: e, st: st);
                      if (!context.mounted) return;
                      Toast.show(context, "An unexpected error occurred");
                    }
                  },
                  child: const Text("Delete local data"),
                ),
              ),
            ],
          )),
        );
      }
    );
  }

}