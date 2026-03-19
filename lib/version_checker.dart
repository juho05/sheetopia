import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/auto_update/auto_update_repository.dart';
import 'package:sheetopia/ui/common/adaptive_dialog_action.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/version_checker_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

enum VersionDialogChoice { ignore, remind, view, install }

class VersionChecker extends StatelessWidget {
  final Widget child;

  const VersionChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<VersionCheckerViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.showUpdateSuccessful) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            viewModel.showUpdateSuccessful = false;
            Toast.show(
              context,
              "Successfully updated to v${viewModel.current}!",
            );
          });
        }
        if (viewModel.newVersionAvailable && !viewModel.isOpen) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            final actions = [
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.ignore),
                child: const Text("Ignore"),
              ),
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.remind),
                child: const Text("Remind later"),
              ),
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.view),
                child: const Text("View"),
              ),
              if (AutoUpdateRepository.autoUpdatesSupported)
                AdaptiveDialogAction(
                  onPressed: () =>
                      Navigator.pop(context, VersionDialogChoice.install),
                  child: const Text("Install"),
                ),
            ];
            viewModel.isOpen = true;
            showAdaptiveDialog<VersionDialogChoice>(
              context: context,
              barrierDismissible: true,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: const Text("New version available"),
                  content: Text(
                    "Current: v${viewModel.current}\nLatest: v${viewModel.latest}",
                  ),
                  actions: actions,
                );
              },
            ).then((choice) async {
              if (!context.mounted) return;
              switch (choice) {
                case VersionDialogChoice.ignore:
                  await viewModel.ignoreVersion();
                  if (context.mounted) {
                    Toast.show(
                      context,
                      "You won't be reminded about this version again",
                    );
                  }
                  break;
                case VersionDialogChoice.view:
                  launchUrl(
                    Uri.https("github.com", "/juho05/sheetopia/releases"),
                  );
                case null:
                case VersionDialogChoice.remind:
                  // default behavior
                  break;
                case VersionDialogChoice.install:
                  context.go("/installUpdate");
              }
              await viewModel.displayedVersionDialog();
            });
          });
        }
        return child;
      },
    );
  }
}
