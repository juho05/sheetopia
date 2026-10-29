/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/ui/common/toast.dart';

class SyncVersionMismatchToast extends StatelessWidget {
  final Widget child;

  const SyncVersionMismatchToast({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mismatch = context.read<SyncRepository>().startupVersionMismatch;
    return ValueListenableBuilder(
      valueListenable: mismatch,
      builder: (context, value, child) {
        if (value != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mismatch.value == null) return;
            mismatch.value = null;
            Toast.show(
              value.message,
              duration: const Duration(seconds: 4),
              replace: false,
            );
          });
        }
        return child!;
      },
      child: child,
    );
  }
}
