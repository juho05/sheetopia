/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
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
    return ChangeNotifierProvider(
      create: (context) => ImportExportViewModel(
        syncRepo: context.read(),
        scoresRepo: context.read(),
        setlistsRepo: context.read(),
        practiceRepo: context.read(),
        importExportRepo: context.read(),
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Import/Export")),
          body: SafeArea(
            child: Consumer<ImportExportViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Heading(text: "Import"),
                    ),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        enabled: viewModel.status == ImportExportStatus.idle,
                        onPressed: () async {
                          try {
                            final success = await viewModel.import(
                              onSelected: () {
                                Toast.show("Importing…");
                              },
                            );
                            if (!success || !context.mounted) return;
                            Toast.show("Import successful!");
                          } on InvalidFileException catch (e, st) {
                            Log.warn(
                              "tried to import invalid file",
                              e: e,
                              st: st,
                            );
                            if (!context.mounted) return;
                            Toast.show(
                              "The selected file is not a valid sheetopia archive!",
                            );
                          } on Exception catch (e, st) {
                            Log.error("failed to import scores", e: e, st: st);
                            if (!context.mounted) return;
                            Toast.show("An unexpected error occurred!");
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            const Text("Import .zip"),
                            if (viewModel.status ==
                                ImportExportStatus.importing)
                              const SizedBox.square(
                                dimension: 15,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Heading(text: "Export"),
                    ),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Builder(
                        builder: (context) {
                          Rect? sharePositionOrigin() {
                            if (Platform.isIOS) {
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              if (box != null) {
                                return box.localToGlobal(Offset.zero) &
                                    box.size;
                              }
                            }
                            return null;
                          }

                          return Button(
                            enabled:
                                viewModel.status == ImportExportStatus.idle,
                            onPressed: () async {
                              Toast.show("Exporting…");
                              try {
                                final success = await viewModel.export(
                                  sharePositionOrigin: sharePositionOrigin(),
                                );
                                if (!success || !context.mounted) return;
                                Toast.show("Export successful!");
                              } on Exception catch (e, st) {
                                Log.error("Export failed", e: e, st: st);
                                if (!context.mounted) return;
                                Toast.show("Export failed!");
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                const Text("Export .zip"),
                                if (viewModel.status ==
                                    ImportExportStatus.exporting)
                                  const SizedBox.square(
                                    dimension: 15,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Heading(text: "Reset"),
                    ),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        enabled: viewModel.status == ImportExportStatus.idle,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: () async {
                          final confirmed = await ConfirmationDialog.showYesNo(
                            context,
                            message:
                                "Sync will be disabled and all local scores, exercises, tags, etc. will be deleted.\n\nRemote data will not be deleted.",
                          );
                          if (confirmed != true) return;

                          // TODO ask whether to delete remote data if logged in

                          try {
                            await viewModel.deleteLocalData();
                            if (!context.mounted) return;
                            Toast.show("Successfully deleted all local data!");
                          } on Exception catch (e, st) {
                            Log.error(
                              "Failed to delete local data",
                              e: e,
                              st: st,
                            );
                            if (!context.mounted) return;
                            Toast.show("An unexpected error occurred");
                          }
                        },
                        child: const Text("Delete local data"),
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
