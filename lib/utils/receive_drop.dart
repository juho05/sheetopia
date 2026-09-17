/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

Future<bool> receiveScore(ScoresRepository repo, Iterable<XFile> files) async {
  try {
    final scores = await repo.importAll(
      files,
      status: ScoreStatus.needsFirstEdit,
    );
    return scores.isNotEmpty;
  } finally {
    await DesktopDrop.instance.clearReceivingCache();
  }
}

Future<bool> receiveExercise(
  ScoresRepository repo,
  Iterable<XFile> files,
) async {
  try {
    await repo.deleteScoresWithUncreatedParent();
    final scores = await repo.importAll(
      files,
      type: ScoreType.exercise,
      status: ScoreStatus.uncreatedParent,
    );
    return scores.isNotEmpty;
  } finally {
    await DesktopDrop.instance.clearReceivingCache();
  }
}
