import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final String? label;
  final void Function()? onPressed;

  const NextButton({super.key, this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: const ButtonStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsetsGeometry.only(left: 14, right: 8),
        ),
      ),
      child: Row(
        spacing: 2,
        mainAxisSize: MainAxisSize.min,
        children: [Text(label ?? "Next"), const Icon(Icons.navigate_next)],
      ),
    );
  }
}
