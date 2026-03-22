/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/updater/updater.dart';

class MacOSUpdateFailedException {
  final String message;
  const MacOSUpdateFailedException(this.message);

  @override
  String toString() {
    return "MacOSUpdateFailedException: $message";
  }
}

class UpdaterMacOS implements Updater {
  static final volumeRegex = RegExp("\\/Volumes\\/(.*)\n");

  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Sheetopia-$version-macOS-universal.dmg";

  @override
  Future<void> install(File downloadedFile) async {
    Log.debug("Mounting DMG ${downloadedFile.path}...");

    final dmgAttachResult = await Process.run("hdiutil", [
      "attach",
      "-nobrowse",
      "-readonly",
      downloadedFile.path,
    ], stdoutEncoding: systemEncoding);
    throwOnNonZeroExitCode(dmgAttachResult);

    final dmgAttachOutput = dmgAttachResult.stdout as String;
    Match? match = volumeRegex.firstMatch(dmgAttachOutput);
    if (match == null) {
      throw MacOSUpdateFailedException(
        "failed to parse attach dmg output to determine volume:\n$dmgAttachOutput",
      );
    }
    String volumePath = "/Volumes/${match.group(1)!}";

    Process.run("/bin/zsh", [
      "-c",
      "/bin/zsh -c \"sleep 2 && cp -pPR \\\"${path.join(volumePath, "Sheetopia.app")}\\\" /Applications/ && xattr -r -d com.apple.quarantine /Applications/Sheetopia.app && sleep 1 && open /Applications/Sheetopia.app; hdiutil detach \\\"$volumePath\\\"\" & disown",
    ]);
    await Future.delayed(const Duration(milliseconds: 250), () => exit(0));
  }
}
