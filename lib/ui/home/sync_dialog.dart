import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
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
                    viewModel.signedIn ? "Sync settings" : "Setup sync",
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
              validationMessages: {"baseUri": (error) => "invalid URI"},
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
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [Text("status")],
    );
  }
}
