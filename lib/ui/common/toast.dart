/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

class Toast {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
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
    Object e, {
    StackTrace? st,
    String errorMsg = "An unexpected error occurred",
  }) {
    Log.error(errorMsg, e: e, st: st);
    show(errorMsg);
  }
}
