/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/annotations/stroke.dart';
import 'package:sheetopia/data/services/database/database.dart';

class AnnotationsRepository {
  final Database _db;

  final BehaviorSubject<String> _updatedAnnotationScoreIds = BehaviorSubject();

  Stream<String> get updatedAnnotationScoreIds =>
      _updatedAnnotationScoreIds.stream;

  AnnotationsRepository({required Database db}) : _db = db;

  Future<List<PageAnnotations>> getAnnotations(String scoreId) async {
    final rows = await _db.managers.annotationsTable
        .filter((f) => f.score.id(scoreId))
        .get();
    return rows
        .map((r) => PageAnnotations.decode(r.pageIndex, r.data))
        .toList();
  }

  Future<void> savePage(String scoreId, PageAnnotations page) async {
    if (page.strokes.isEmpty) {
      await _db.managers.annotationsTable
          .filter((f) => f.score.id(scoreId) & f.pageIndex(page.pageIndex))
          .delete();
    } else {
      await _db
          .into(_db.annotationsTable)
          .insert(
            AnnotationsTableCompanion.insert(
              score: scoreId,
              pageIndex: page.pageIndex,
              data: page.encode(),
              updatedAt: Value(DateTime.now().toUtc()),
              uploaded: const Value(false),
            ),
            onConflict: DoUpdate(
              (old) => AnnotationsTableCompanion(
                data: Value(page.encode()),
                updatedAt: Value(DateTime.now().toUtc()),
                uploaded: const Value(false),
              ),
              target: [
                _db.annotationsTable.score,
                _db.annotationsTable.pageIndex,
              ],
            ),
          );
    }
    _updatedAnnotationScoreIds.add(scoreId);
  }

  void dispose() {
    _updatedAnnotationScoreIds.close();
  }
}
