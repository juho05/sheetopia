/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:sheetopia/utils/app_shutdown.dart';
import 'package:window_manager/window_manager.dart';

class WindowCloseListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    appIsClosing = true;
    final bool isPreventClose = await windowManager.isPreventClose();
    if (!isPreventClose) return;
    await windowManager.setPreventClose(false);
    await windowManager.close();
    exit(0);
  }
}
