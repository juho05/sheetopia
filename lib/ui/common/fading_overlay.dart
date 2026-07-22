/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class FadingOverlay extends StatelessWidget {
  final bool visible;
  final Duration duration;
  final Widget child;

  const FadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: child,
      ),
    );
  }
}
