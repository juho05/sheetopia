/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/updater/updater.dart';

class UpdaterWindows implements Updater {
  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Sheetopia-$version-windows-x86-64.exe";

  @override
  Future<void> install(File downloadedFile) async {
    Log.debug("Running installer ${downloadedFile.path}...");
    Process.run("powershell", [
      "-Command",
      "Start-Sleep -Seconds 2; &'${downloadedFile.absolute.path}' /SP-",
    ]);
    await Future.delayed(const Duration(seconds: 1), () => exit(0));
  }
}
