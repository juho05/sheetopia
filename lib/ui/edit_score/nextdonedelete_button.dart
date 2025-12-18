import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/next_button.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class NextDoneDeleteButton extends StatelessWidget {
  final EditScoreViewModel viewModel;

  const NextDoneDeleteButton({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return viewModel.hasNext
        ? NextButton(onPressed: () => viewModel.next())
        : viewModel.isImport
        ? FilledButton(
            onPressed: () => context.pop(),
            child: const Text("Done"),
          )
        : FilledButton.icon(
            onPressed: () async {
              final confirmation = await ConfirmationDialog.showYesNo(
                context,
                message: "Delete '${viewModel.score!.title}'?",
              );
              if (confirmation != true) return;
              await viewModel.delete();
              if (context.mounted) {
                Toast.show(
                  context,
                  "Successfully deleted score '${viewModel.score!.title}'!",
                );
                context.go("/");
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text("Delete"),
          );
  }
}
