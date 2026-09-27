/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:material_ui/material_ui.dart';

class CenteredScrollView extends StatelessWidget {
  final double maxWidth;
  final List<Widget> Function(BuildContext context, double contentWidth)
  builder;

  const CenteredScrollView({
    super.key,
    required this.maxWidth,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = min(constraints.maxWidth, maxWidth);
        final inset = (constraints.maxWidth - contentWidth) / 2;
        return CustomScrollView(
          slivers: [
            for (final sliver in builder(context, contentWidth))
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                sliver: sliver,
              ),
          ],
        );
      },
    );
  }
}
