/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/practice_repository.dart';

Future<String?> runningPracticeLocation(PracticeRepository repo) async {
  final entry = await repo.getRunningSessionEntry();
  if (entry == null) return null;

  final routineEntryId = entry.routineEntryId;
  final location = routineEntryId == null
      ? null
      : await repo.getRoutineEntryLocation(routineEntryId);
  final exerciseExists = await repo.getExercise(entry.exerciseId) != null;

  if (!exerciseExists || (routineEntryId != null && location == null)) {
    await repo.checkpointSessionEntry(
      entry,
      now: entry.runningSince,
      stop: true,
    );
    return null;
  }

  if (location != null) {
    return "/practice/routines/${location.routineId}/details/play"
        "?startIndex=${location.index}";
  }
  return "/practice/exercises/${entry.exerciseId}/play";
}
