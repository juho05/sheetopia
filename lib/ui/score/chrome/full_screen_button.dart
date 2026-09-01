/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';

class FullScreenButton extends StatelessWidget {
  final bool visible;
  final bool fullScreen;
  final void Function() onPressed;

  const FullScreenButton({
    super.key,
    required this.visible,
    required this.fullScreen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!supportsFullScreen) return const SizedBox.shrink();
    return FadingOverlay(
      visible: visible,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IconButton.filled(
            onPressed: onPressed,
            color: Colors.white,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Colors.black.withAlpha(100),
              ),
            ),
            iconSize: 26,
            padding: const EdgeInsets.all(10),
            icon: Icon(fullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ),
      ),
    );
  }
}
