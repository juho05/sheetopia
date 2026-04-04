/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/scores_repository.dart';

class ImportExportRepository {
  final ScoresRepository _scoresRepo;

  ImportExportRepository({required ScoresRepository scoresRepo}) : _scoresRepo = scoresRepo;
}