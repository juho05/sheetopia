/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

/// Request Android 17+ [Permission.accessLocalNetwork] before LAN sync.
Future<bool> ensureLocalNetworkPermission() async {
  if (!Platform.isAndroid) return true;

  var status = await Permission.accessLocalNetwork.status;
  if (status.isGranted) return true;

  status = await Permission.accessLocalNetwork.request();
  if (status.isGranted) return true;

  Log.warn("Local network permission not granted (status=$status)");
  return false;
}
