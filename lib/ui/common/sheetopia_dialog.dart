/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/surface.dart';

Future<T?> showSheetopiaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        Surface(level: SurfaceLevel.dialog, child: builder(context)),
  );
}

class SheetopiaDialog extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final EdgeInsets insetPadding;
  final EdgeInsetsGeometry contentPadding;
  const SheetopiaDialog({
    super.key,
    this.maxWidth = 560,
    this.insetPadding = const EdgeInsets.all(8),
    this.contentPadding = const EdgeInsets.all(12),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      constraints: BoxConstraints(maxWidth: maxWidth),
      insetPadding: insetPadding,
      child: Padding(padding: contentPadding, child: child),
    );
  }
}
