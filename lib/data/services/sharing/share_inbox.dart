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

/// Name of the app group subdirectory the iOS share extension copies incoming
/// attachments into. Keep in sync with `kShareInboxDirectory` in
/// `ios/Share Extension/FSIShareViewController.swift`.
const String shareInboxDirectory = "ShareInbox";

/// Deletes the copies the iOS share extension made in the app group container.
///
/// The extension copies every attachment into `ShareInbox/<share id>/` and the
/// import copies it again into the app's own storage, so without this every
/// shared score would be stored twice, permanently, and invisibly to the app's
/// own storage accounting.
///
/// Called after every share import, successful or not: a file we could not
/// import is exactly as useless to us as one we did.
///
/// Only iOS is handled. On Android the shared path can point at the user's
/// original file rather than at a copy made for us, so deleting it would
/// destroy user data.
Future<void> cleanUpSharedFiles(Iterable<String> paths) async {
  if (!Platform.isIOS) return;

  final handled = <String>{};
  for (final p in paths) {
    // Text and URL shares carry their content in place of a path.
    if (!path.isAbsolute(p)) continue;

    final dir = path.dirname(p);
    try {
      if (path.basename(path.dirname(dir)) == shareInboxDirectory) {
        // Delete the whole share directory rather than the single file, so
        // video thumbnails and attachments that never reached us (a partly
        // delivered share) go with it.
        if (handled.add(dir)) await Directory(dir).delete(recursive: true);
      } else {
        await File(p).delete();
      }
    } catch (e, st) {
      Log.warn("Failed to clean up shared file $p", e: e, st: st);
    }
  }
}
