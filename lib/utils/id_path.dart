/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:path/path.dart' as path;

final _safeId = RegExp(r'^[A-Za-z0-9_-]+$', multiLine: false);

/// Ids can come from the sync server or an import file, so they must never
/// be joined into a path directly.
String idPath(String parent, String id) {
  if (!_safeId.hasMatch(id)) {
    throw ArgumentError.value(id, "id", "not usable as a path segment");
  }
  return path.join(parent, id);
}
