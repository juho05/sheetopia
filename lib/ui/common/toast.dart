import 'package:flutter/material.dart';

class Toast {
  static void show(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        padding: const EdgeInsets.all(8),
        showCloseIcon: true,
      ),
    );
  }

  static void exception(
    BuildContext context,
    Object e, {
    StackTrace? st,
    String errorMsg = "An unexpected error occurred",
  }) {
    print("$e\n$st");
    show(context, errorMsg);
  }
}
