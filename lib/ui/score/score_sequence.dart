/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class ScoreSequence implements Listenable {
  String? get currentScoreId;

  // -1 if there is no current position
  int get position;

  File? get nextFile;

  File? get previousFile;

  // True once the underlying collection is gone
  bool get deleted;

  bool next();

  bool previous();
}
