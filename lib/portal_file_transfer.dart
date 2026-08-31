/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:dbus/dbus.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

Future<List<String>> retrievePortalFiles(String key) async {
  final client = DBusClient.session();
  try {
    final result = await client.callMethod(
      destination: "org.freedesktop.portal.Documents",
      path: DBusObjectPath("/org/freedesktop/portal/documents"),
      interface: "org.freedesktop.portal.FileTransfer",
      name: "RetrieveFiles",
      values: [DBusString(key), DBusDict.stringVariant({})],
      replySignature: DBusSignature("as"),
    );
    return result.values.first.asStringArray().toList();
  } catch (e, st) {
    Log.warn(
      "failed to resolve portal file transfer",
      e: e,
      st: st,
      tag: "portal",
    );
    return const [];
  } finally {
    await client.close();
  }
}
