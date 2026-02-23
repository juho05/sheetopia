import 'dart:io';

import 'package:window_manager/window_manager.dart';

class WindowCloseListener extends WindowListener {
  @override
  Future<void> onWindowClose() async {
    final bool isPreventClose = await windowManager.isPreventClose();
    if (!isPreventClose) return;
    await windowManager.setPreventClose(false);
    await windowManager.close();
    if (!Platform.isMacOS) {
      exit(0);
    }
  }
}
