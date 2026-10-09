/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';

class OverlayIconButton extends StatelessWidget {
  final Widget icon;
  final String? tooltip;
  final VoidCallback onPressed;

  const OverlayIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox.square(
        dimension: 32,
        child: IconButton.filled(
          color: Colors.white,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              Colors.black.withAlpha(100),
            ),
          ),
          icon: icon,
          tooltip: tooltip,
          iconSize: 20,
          padding: const EdgeInsets.all(0),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
