import 'dart:io';

import 'package:flutter/material.dart';

Future<T?> showSheetopiaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final openTime = DateTime.now();
  return showDialog<T>(
    context: context,
    barrierDismissible: !Platform.isIOS,
    builder: Platform.isIOS
        ? (context) {
            // workaround for
            // https://github.com/flutter/flutter/issues/177992
            return TapRegion(
              onTapOutside: (_) {
                if (DateTime.now().difference(openTime) <
                    const Duration(milliseconds: 500)) {
                  return;
                }
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: builder(context),
            );
          }
        : builder,
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
