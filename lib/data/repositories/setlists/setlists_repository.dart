/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlist.dart';
import 'package:sheetopia/data/services/database/database.dart';

class SetlistsRepository {
  final Database _db;
  final ScoresRepository _scoresRepo;

  final BehaviorSubject<({Set<String> changed, bool needsUpload})>
  _updatedSetlistIds = BehaviorSubject();

  Stream<Set<String>> get updatedSetlistIds =>
      _updatedSetlistIds.stream.map((event) => event.changed);

  Stream<Set<String>> get locallyUpdatedSetlistIds => _updatedSetlistIds.stream
      .where((event) => event.needsUpload)
      .map((event) => event.changed);

  SetlistsRepository({
    required Database db,
    required ScoresRepository scoresRepo,
  }) : _db = db,
       _scoresRepo = scoresRepo {
    _scoresRepo.deletedScoreIds.listen(removeDeletedScoreEntries);
  }

  Future<List<Setlist>> getSetlists({String filter = ""}) async {
    final count = _db.setlistEntriesTable.position.count();
    final query =
        _db.selectOnly(_db.setlistsTable).join([
            leftOuterJoin(
              _db.setlistEntriesTable,
              _db.setlistEntriesTable.setlist.equalsExp(_db.setlistsTable.id),
              useColumns: false,
            ),
          ])
          ..addColumns([
            _db.setlistsTable.id,
            _db.setlistsTable.name,
            _db.setlistsTable.updatedAt,
            count,
          ])
          ..groupBy([_db.setlistsTable.id])
          ..orderBy([
            OrderingTerm.asc(_db.setlistsTable.name.lower()),
            OrderingTerm.asc(_db.setlistsTable.id),
          ]);
    if (filter.isNotEmpty) {
      query.where(_db.setlistsTable.name.contains(filter));
    }
    return (await query.get())
        .map(
          (row) => Setlist(
            id: row.read(_db.setlistsTable.id)!,
            name: row.read(_db.setlistsTable.name)!,
            updatedAt: row.read(_db.setlistsTable.updatedAt)!.toUtc(),
            entryCount: row.read(count)!,
          ),
        )
        .toList();
  }

  Future<int> countSetlists() async {
    final count = _db.setlistsTable.id.count();
    final query = _db.selectOnly(_db.setlistsTable)..addColumns([count]);
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<Setlist?> getSetlist(String id) async {
    final setlist = await _db.managers.setlistsTable
        .filter((f) => f.id(id))
        .getSingleOrNull();
    if (setlist == null) return null;

    final query =
        _db.select(_db.setlistEntriesTable).join([
            leftOuterJoin(
              _db.scoresTable,
              _db.scoresTable.id.equalsExp(_db.setlistEntriesTable.score),
            ),
          ])
          ..where(_db.setlistEntriesTable.setlist.equals(id))
          ..orderBy([OrderingTerm.asc(_db.setlistEntriesTable.position)]);

    final entries = <SetlistEntry>[];
    for (final row in await query.get()) {
      final entry = row.readTable(_db.setlistEntriesTable);
      final score = row.readTableOrNull(_db.scoresTable);
      entries.add(
        SetlistEntry(
          scoreId: entry.score,
          score: score == null ? null : await _entryScore(score),
        ),
      );
    }

    return Setlist(
      id: setlist.id,
      name: setlist.name,
      updatedAt: setlist.updatedAt.toUtc(),
      entryCount: entries.length,
      entries: entries,
    );
  }

  // Tags, genres and instruments are left empty: the setlist views only show
  // title, composer and the thumbnail, and the play view refetches the full
  // score through ScoresRepository.getScore.
  Future<Score> _entryScore(ScoresTableData score) async {
    return Score(
      id: score.id,
      title: score.title,
      composer: score.composer,
      source: score.source,
      sourceLink: score.sourceLink,
      notes: score.notes,
      annotations: score.annotations,
      genres: const [],
      instruments: const [],
      tags: const [],
      metadataUpdatedAt: score.metadataUpdatedAt.toUtc(),
      fileUpdatedAt: score.fileUpdatedAt.toUtc(),
      fileType: score.fileType,
      file: score.fileDownloaded
          ? await _scoresRepo.scoreFile(score.id, score.fileType)
          : null,
    );
  }

  Future<Setlist> createSetlist({required String name}) async {
    final setlist = await _db.managers.setlistsTable.createReturning(
      (o) => o(
        id: _db.newId(),
        name: name,
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    _updatedSetlistIds.add((changed: {setlist.id}, needsUpload: true));
    return Setlist(
      id: setlist.id,
      name: setlist.name,
      updatedAt: setlist.updatedAt.toUtc(),
      entryCount: 0,
    );
  }

  Future<void> renameSetlist(String id, String name) async {
    await _db.managers.setlistsTable
        .filter((f) => f.id(id))
        .update(
          (o) => o(
            name: Value(name),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    _updatedSetlistIds.add((changed: {id}, needsUpload: true));
  }

  Future<void> deleteSetlist(String id) async {
    await _db.transaction(() async {
      await _db.managers.setlistsTable.filter((f) => f.id(id)).delete();
      await _db.managers.deletedSetlistsTable.create(
        (o) => o(setlistId: id, deletedAt: Value(DateTime.now().toUtc())),
      );
    });
    _updatedSetlistIds.add((changed: {id}, needsUpload: true));
  }

  Future<void> addScores(String setlistId, List<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    await _db.transaction(() async {
      final maxPosition = _db.setlistEntriesTable.position.max();
      final query = _db.selectOnly(_db.setlistEntriesTable)
        ..addColumns([maxPosition])
        ..where(_db.setlistEntriesTable.setlist.equals(setlistId));
      final start = ((await query.getSingle()).read(maxPosition) ?? -1) + 1;
      await _db.managers.setlistEntriesTable.bulkCreate(
        (o) => scoreIds.indexed.map(
          (e) => o(setlist: setlistId, score: e.$2, position: start + e.$1),
        ),
      );
      await _touch(setlistId);
    });
    _updatedSetlistIds.add((changed: {setlistId}, needsUpload: true));
  }

  Future<void> removeEntry(String setlistId, int index) async {
    await _rewriteEntries(setlistId, (scoreIds) => scoreIds.removeAt(index));
  }

  Future<void> moveEntry(String setlistId, int from, int to) async {
    await _rewriteEntries(
      setlistId,
      (scoreIds) => scoreIds.insert(to, scoreIds.removeAt(from)),
    );
  }

  Future<void> _rewriteEntries(
    String setlistId,
    void Function(List<String> scoreIds) mutate,
  ) async {
    await _db.transaction(() async {
      final query = _db.select(_db.setlistEntriesTable)
        ..where((t) => t.setlist.equals(setlistId))
        ..orderBy([(t) => OrderingTerm.asc(t.position)]);
      final scoreIds = (await query.get()).map((e) => e.score).toList();
      mutate(scoreIds);
      await _db.managers.setlistEntriesTable
          .filter((f) => f.setlist.id(setlistId))
          .delete();
      await _db.managers.setlistEntriesTable.bulkCreate(
        (o) => scoreIds.indexed.map(
          (e) => o(setlist: setlistId, score: e.$2, position: e.$1),
        ),
      );
      await _touch(setlistId);
    });
    _updatedSetlistIds.add((changed: {setlistId}, needsUpload: true));
  }

  Future<void> removeDeletedScoreEntries(Set<String> scoreIds) async {
    if (scoreIds.isEmpty) return;
    final affected = <String>{};
    await _db.transaction(() async {
      final setlist = _db.setlistEntriesTable.setlist;
      final query = _db.selectOnly(_db.setlistEntriesTable, distinct: true)
        ..addColumns([setlist])
        ..where(_db.setlistEntriesTable.score.isIn(scoreIds));
      affected.addAll((await query.get()).map((row) => row.read(setlist)!));
      if (affected.isEmpty) return;
      await _db.managers.setlistEntriesTable
          .filter((f) => f.score.isIn(scoreIds))
          .delete();
      await _db.managers.setlistsTable
          .filter((f) => f.id.isIn(affected))
          .update(
            (o) => o(
              updatedAt: Value(DateTime.now().toUtc()),
              uploaded: const Value(false),
            ),
          );
    });
    if (affected.isEmpty) return;
    _updatedSetlistIds.add((changed: affected, needsUpload: true));
  }

  Future<void> deleteAllSetlists() async {
    final wiped = <String>{};
    await _db.transaction(() async {
      wiped.addAll(await _db.managers.setlistsTable.map((s) => s.id).get());
      await _db.managers.setlistEntriesTable.delete();
      await _db.managers.setlistsTable.delete();
      await _db.managers.deletedSetlistsTable.delete();
    });
    if (wiped.isEmpty) return;
    _updatedSetlistIds.add((changed: wiped, needsUpload: false));
  }

  void remoteChangedSetlists(Set<String> setlistIds) {
    if (setlistIds.isEmpty) return;
    _updatedSetlistIds.add((changed: setlistIds, needsUpload: false));
  }

  Future<void> _touch(String setlistId) async {
    await _db.managers.setlistsTable
        .filter((f) => f.id(setlistId))
        .update(
          (o) => o(
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
  }
}
