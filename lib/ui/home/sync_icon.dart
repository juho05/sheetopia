/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/ui/home/sync_dialog.dart';

class SyncIcon extends StatelessWidget {
  const SyncIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final syncRepository = context.read<SyncRepository>();
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () {
        SyncDialog.show(context);
      },
      icon: SizedBox.square(
        dimension: 24,
        child: ValueListenableBuilder(
          valueListenable: syncRepository.state,
          builder: (context, state, _) {
            return switch (state) {
              SyncState.none => const Icon(Icons.cloud_off_outlined),
              SyncState.failure => const Icon(Icons.wifi_off),
              SyncState.partial => const Icon(Symbols.cloud_alert),
              SyncState.success => const Icon(Icons.cloud_done),
              SyncState.syncing => Stack(
                children: [
                  const Icon(Icons.cloud),
                  Padding(
                    padding: const EdgeInsetsGeometry.all(8),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.surface,
                      strokeCap: StrokeCap.round,
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}
