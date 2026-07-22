/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';

class ImportExportViewModel extends ChangeNotifier {
  final SyncRepository _syncRepo;
  final ScoresRepository _scoresRepo;
  final SetlistsRepository _setlistsRepo;
  final ImportExportRepository _repo;

  ImportExportStatus get status => _repo.status;

  ImportExportViewModel({
    required SyncRepository syncRepo,
    required ScoresRepository scoresRepo,
    required SetlistsRepository setlistsRepo,
    required ImportExportRepository importExportRepo,
  }) : _syncRepo = syncRepo,
       _scoresRepo = scoresRepo,
       _setlistsRepo = setlistsRepo,
       _repo = importExportRepo {
    _repo.addListener(notifyListeners);
  }

  Future<void> deleteLocalData() async {
    await _syncRepo.logout();
    await _scoresRepo.deleteAll();
    await _setlistsRepo.deleteAllSetlists();
  }

  Future<bool> import({void Function()? onSelected}) async {
    return _repo.import(onSelected: onSelected);
  }

  Future<bool> export() async {
    return _repo.export();
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
