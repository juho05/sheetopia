/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';

class ImportExportViewModel {
  final SyncRepository _syncRepo;
  final ScoresRepository _scoresRepo;

  ImportExportViewModel({required SyncRepository syncRepo, required ScoresRepository scoresRepo}) : _syncRepo = syncRepo, _scoresRepo = scoresRepo;

  Future<void> deleteLocalData() async {
    await _syncRepo.logout();
    await _scoresRepo.deleteAll();
  }
}