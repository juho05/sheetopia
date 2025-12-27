import 'package:flutter/material.dart';

Future<T?> showSheetopiaDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: builder,
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
