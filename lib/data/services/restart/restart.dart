/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

class Restart {
  static bool supported = !kIsWeb && AppImageRepository.isAppImage;

  static Future<void> restart() async {
    if (kIsWeb) return;

    if (AppImageRepository.isAppImage) {
      return _restartAppImage();
    }
    throw UnimplementedError("restarts are not supported on this platform");
  }

  static Future<void> _restartAppImage() async {
    Log.info("Restarting application...");

    Process.run("/bin/bash", [
      "-c",
      "/bin/bash -c \"sleep 2 && ${AppImageRepository.appImageFile.path.replaceAll(" ", "\\ ")}\" & disown",
    ]);

    await Future.delayed(const Duration(milliseconds: 250), () => exit(0));
  }
}
