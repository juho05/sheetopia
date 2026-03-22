/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/services/restart/restart.dart';
import 'package:sheetopia/integrate_appimage_viewmodel.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/toast.dart';

class IntegrateAppImage extends StatelessWidget {
  final Widget child;

  const IntegrateAppImage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppImageRepository.isAppImage) {
      return child;
    }
    return Consumer<IntegrateAppImageViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.askToIntegrate) {
          viewModel.shownDialog();
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            final answer = await ConfirmationDialog.showYesNoCancel(
              context,
              title: "Integrate AppImage?",
              message:
                  "Would you like to integrate Sheetopia into your desktop environment?",
              cancelBtn: "Later",
            );
            if (answer == null) return;
            if (!answer) {
              await viewModel.disable();
              return;
            }
            try {
              await viewModel.integrate();
            } on Exception catch (e, st) {
              Log.error("Failed to integrate AppImage", e: e, st: st);
              if (!context.mounted) return;
              Toast.show(context, "Failed to integrate AppImage!");
              return;
            }
            Restart.restart();
          });
        }
        return child;
      },
    );
  }
}
