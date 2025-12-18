import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final String? label;
  final void Function()? onPressed;
  final bool showIcon;

  const NextButton({
    super.key,
    this.label,
    this.showIcon = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsetsGeometry.only(left: 14, right: showIcon ? 8 : 14),
        ),
      ),
      child: Row(
        spacing: 2,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label ?? "Next"),
          if (showIcon) const Icon(Icons.navigate_next),
        ],
      ),
    );
  }
}
