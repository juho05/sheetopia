/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart';
import 'package:provider/provider.dart';

class UpgradeMessages extends StatelessWidget {
  final Widget child;

  const UpgradeMessages({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<UpgradeMessagesViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.messages.isNotEmpty) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            final messages = viewModel.messages;
            if (messages.isEmpty || !context.mounted) return;
            // acknowledge before showing to prevent duplicate dialogs
            viewModel.acknowledge();
            await showUpgradeMessagesDialog(context, messages);
          });
        }
        return child;
      },
    );
  }
}
