/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/material.dart';

class PlayToolbar extends StatelessWidget {
  static const double height = 36;
  static const double maxCenterWidth = 320;

  final List<Widget> leading;
  final Widget? center;
  final List<Widget> trailing;

  const PlayToolbar({
    super.key,
    this.leading = const [],
    this.center,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = this.center;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            SizedBox(
              height: height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: IconButtonTheme(
                          data: IconButtonThemeData(
                            style: IconButton.styleFrom(
                              iconSize: 20,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          child: Row(
                            spacing: 2,
                            children: [...leading, const Spacer(), ...trailing],
                          ),
                        ),
                      ),
                      if (center != null)
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: min(
                              maxCenterWidth,
                              constraints.maxWidth / 2,
                            ),
                          ),
                          child: center,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
