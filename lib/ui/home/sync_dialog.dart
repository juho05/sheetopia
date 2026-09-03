/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/surface.dart';
import 'package:sheetopia/ui/home/sync_dialog_viewmodel.dart';

class SyncDialog extends StatelessWidget {
  final SyncDialogViewModel viewModel;

  const SyncDialog._({required this.viewModel});

  static Future<void> show(BuildContext context) {
    return showSheetopiaDialog(
      context: context,
      builder: (context) =>
          SyncDialog._(viewModel: SyncDialogViewModel(repo: context.read())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    viewModel.signedIn ? "Sync status" : "Setup sync",
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (!viewModel.signedIn) _LoginView(viewModel: viewModel),
                if (viewModel.signedIn) _StatusView(viewModel: viewModel),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  final SyncDialogViewModel viewModel;

  const _LoginView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReactiveForm(
      formGroup: viewModel.form,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            ReactiveTextField(
              formControlName: "url",
              validationMessages: {
                "baseUri": (error) => "invalid URI",
                "insecureHttp": (error) =>
                    "http:// is only allowed for servers on the local "
                    "network. Use https:// for remote connections.",
              },
              autofillHints: [AutofillHints.url],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Server URL",
              ),
            ),
            ReactiveTextField(
              formControlName: "user",
              autofillHints: [AutofillHints.username],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Username",
              ),
            ),
            ReactiveTextField(
              formControlName: "password",
              autofillHints: [AutofillHints.password],
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Password",
              ),
              onSubmitted: (control) {
                if (viewModel.form.valid) {
                  viewModel.login();
                }
              },
            ),
            if (viewModel.errorText != null)
              Text(
                "ERROR: ${viewModel.errorText!}",
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.error,
                ),
                softWrap: true,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: AlignmentGeometry.bottomRight,
                child: ReactiveFormConsumer(
                  builder: (context, form, child) {
                    return FilledButton(
                      onPressed: form.valid && !viewModel.loading
                          ? () {
                              viewModel.login();
                            }
                          : null,
                      child: viewModel.loading
                          ? const Text("Loading…")
                          : const Text("Connect"),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final SyncDialogViewModel viewModel;

  const _StatusView({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium!.copyWith(
      fontWeight: FontWeight.w500,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Material(
          borderRadius: BorderRadius.circular(12),
          color: Surface.raisedOf(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Heading(text: "Status"),
                Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text("State:", style: labelStyle),
                    ),
                    Expanded(
                      child: Text(
                        switch (viewModel.state) {
                          SyncState.none => "not syncing",
                          SyncState.failure => "last sync failed",
                          SyncState.partial => "some items failed to sync",
                          SyncState.syncing => "syncing",
                          SyncState.success => "waiting for next sync",
                        },
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text("Last sync:", style: labelStyle),
                    ),
                    Expanded(
                      child: Text(
                        viewModel.lastSync ?? "never",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentGeometry.bottomRight,
                  child: FilledButton(
                    onPressed: viewModel.state != SyncState.syncing
                        ? () {
                            viewModel.syncNow();
                          }
                        : null,
                    child: const Text("Sync now"),
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          borderRadius: BorderRadius.circular(12),
          color: Surface.raisedOf(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Heading(text: "Connection details"),
                Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text("Server:", style: labelStyle),
                    ),
                    Expanded(
                      child: Text(
                        viewModel.server,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text("User:", style: labelStyle),
                    ),
                    Expanded(
                      child: Text(
                        viewModel.user,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentGeometry.bottomRight,
                  child: FilledButton(
                    onPressed: () async {
                      final confirmation = await ConfirmationDialog.showYesNo(
                        context,
                        message: "Sign out and stop syncing with this server?",
                      );
                      if (confirmation == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        await viewModel.logout();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    child: const Text("Logout"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
