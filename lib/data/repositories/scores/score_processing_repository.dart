/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/score_processing/score_processing_service.dart';

class ScoreProcessingRepository {
  static const int processingVersion = 1;

  final Database _db;
  final ScoresRepository _scoresRepo;
  final ScoreProcessingService _service;

  final List<StreamSubscription> _subscriptions = [];

  // file versions that failed in this session, retried once the file changes
  final Map<String, DateTime> _failed = {};

  Future<void>? _run;
  bool _rerun = false;
  bool _disposed = false;

  ScoreProcessingRepository({
    required this._db,
    required this._scoresRepo,
    required this._service,
  }) {
    _subscriptions.add(_scoresRepo.processingRequests.listen((_) => process()));
    process();
  }

  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _service.stop();
  }

  /// Completes once no outdated score is left.
  Future<void> process() {
    if (_disposed) return Future.value();
    final run = _run;
    if (run != null) {
      _rerun = true;
      return run;
    }
    return _run = _processAll().whenComplete(() => _run = null);
  }

  Future<void> _processAll() async {
    try {
      do {
        _rerun = false;
        await _forgetChangedFailures();
        while (!_disposed) {
          final next = await _nextUnprocessed();
          if (next == null) break;
          await _processScore(next.id, next.fileUpdatedAt);
        }
      } while (_rerun && !_disposed);
    } catch (e, st) {
      Log.error("Score processing failed", e: e, st: st);
    } finally {
      _service.stop();
    }
  }

  Future<({String id, DateTime fileUpdatedAt})?> _nextUnprocessed() async {
    final s = _db.scoresTable;
    final q = _db.selectOnly(s)
      ..addColumns([s.id, s.fileUpdatedAt])
      ..where(
        s.fileType.equals(FileType.pdf.name) &
            s.fileDownloaded.isValue(true) &
            (s.processingVersion.isNull() |
                s.processingVersion.isSmallerThanValue(processingVersion)),
      )
      ..orderBy([OrderingTerm.desc(s.recentTime), OrderingTerm.asc(s.id)])
      ..limit(1);
    if (_failed.isNotEmpty) q.where(s.id.isNotIn(_failed.keys));
    final row = await q.getSingleOrNull();
    if (row == null) return null;
    return (id: row.read(s.id)!, fileUpdatedAt: row.read(s.fileUpdatedAt)!);
  }

  Future<void> _processScore(String id, DateTime fileUpdatedAt) async {
    final stopwatch = Stopwatch()..start();
    final ScoreProcessingResult result;
    try {
      final file = await _scoresRepo.scoreFile(id, FileType.pdf);
      result = await _service.processPdf(file.path);
    } catch (e, st) {
      if (_disposed) return;
      Log.error("Failed to process file of score $id", e: e, st: st);
      _failed[id] = fileUpdatedAt;
      return;
    }

    final saved = await _db.transaction(() async {
      final current =
          await (_db.selectOnly(_db.scoresTable)
                ..addColumns([_db.scoresTable.fileUpdatedAt])
                ..where(_db.scoresTable.id.equals(id)))
              .map((row) => row.read(_db.scoresTable.fileUpdatedAt))
              .getSingleOrNull();
      if (current != fileUpdatedAt) return false;
      await _db.managers.scoresTable
          .filter((f) => f.id(id))
          .update(
            (o) => o(
              processingVersion: const Value(processingVersion),
              backgroundColor: Value(result.backgroundColor),
            ),
          );
      return true;
    });
    final color = result.backgroundColor?.toRadixString(16).padLeft(8, "0");
    Log.debug(
      "Processed score $id (${result.pageCount} pages, background "
      "${color ?? "none"}) in ${stopwatch.elapsedMilliseconds} ms"
      "${saved ? "" : ", discarded because the file changed"}",
    );
  }

  Future<void> _forgetChangedFailures() async {
    if (_failed.isEmpty) return;
    final rows =
        await (_db.selectOnly(_db.scoresTable)
              ..addColumns([_db.scoresTable.id, _db.scoresTable.fileUpdatedAt])
              ..where(_db.scoresTable.id.isIn(_failed.keys)))
            .get();
    final current = {
      for (final row in rows)
        row.read(_db.scoresTable.id)!: row.read(_db.scoresTable.fileUpdatedAt),
    };
    _failed.removeWhere((id, fileUpdatedAt) => current[id] != fileUpdatedAt);
  }
}
