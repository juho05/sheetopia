/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/services.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

const _channel = MethodChannel('sheetopia/file_export');

Future<bool> exportFileMobile({
  required String path,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final uri = await _channel.invokeMethod<String>('exportFile', {
      'path': path,
      'fileName': fileName,
      'mimeType': mimeType,
    });
    return uri != null;
  } on PlatformException catch (e, st) {
    Log.error("failed to export $fileName", e: e, st: st);
    return false;
  }
}
