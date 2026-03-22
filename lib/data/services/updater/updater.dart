/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:sheetopia/data/repositories/version/version.dart';

abstract class Updater {
  Future<String> generateDownloadFileName(Version version);

  Future<void> install(File downloadedFile);
}

class NonZeroExitException {
  final int exitCode;
  final dynamic errOut;
  const NonZeroExitException(this.exitCode, this.errOut);

  @override
  String toString() {
    return "process exited with status code $exitCode: \n$errOut";
  }
}

void throwOnNonZeroExitCode(ProcessResult result) {
  if (result.exitCode != 0) {
    throw NonZeroExitException(result.exitCode, result.stderr);
  }
}
