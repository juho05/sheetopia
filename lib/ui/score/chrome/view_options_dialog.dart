/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/score/annotation_mode.dart';

class ViewOptionsDialog extends StatelessWidget {
  final AnnotationMode annotation;

  const ViewOptionsDialog({super.key, required this.annotation});

  static Future<void> show(
    BuildContext context, {
    required AnnotationMode annotation,
  }) {
    return showSheetopiaDialog<void>(
      context: context,
      builder: (context) => ViewOptionsDialog(annotation: annotation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.read<SettingsRepository>();
    final pageTurning = settings.pageTurning;
    final appearance = settings.appearanceSettings;
    final pageCrop = settings.pageCrop;
    return SheetopiaDialog(
      maxWidth: 420,
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          pageTurning,
          appearance,
          pageCrop,
          annotation,
        ]),
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "View options",
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Gradual page turns"),
                  value: pageTurning.gradualPageTurns,
                  onChanged: (value) => pageTurning.gradualPageTurns = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Match paper color"),
                  value: appearance.scoreBackground,
                  onChanged: (value) => appearance.scoreBackground = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Crop page margins"),
                  value: pageCrop.enabled,
                  onChanged: (value) => pageCrop.enabled = value,
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.draw),
                      label: const Text("Annotate"),
                      onPressed: annotation.canEnter
                          ? () {
                              Navigator.pop(context);
                              annotation.toggle();
                            }
                          : null,
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
