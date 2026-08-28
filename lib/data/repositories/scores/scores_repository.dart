/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:diacritic/diacritic.dart';
import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/instr_expression.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

class InvalidFileTypeException implements Exception {
  final String filePath;

  const InvalidFileTypeException({required this.filePath});

  @override
  String toString() {
    final ext = path.extension(filePath);
    return "Invalid file type $ext: $filePath";
  }
}

class ScoresRepository {
  final Database _db;
  final ThumbnailService _thumbnailService;

  static const List<XTypeGroup> scoreFileTypeGroup = [
    XTypeGroup(
      label: "PDF",
      extensions: <String>["pdf"],
      mimeTypes: ["application/pdf"],
      uniformTypeIdentifiers: ["com.adobe.pdf"],
    ),
  ];

  final BehaviorSubject<({Set<String> changed, bool remoteTriggered})>
  _updatedScoreIds = BehaviorSubject();

  Stream<Set<String>> get updatedScoreIds =>
      _updatedScoreIds.stream.map((event) => event.changed);

  Stream<Set<String>> get locallyUpdatedScoreIds => _updatedScoreIds.stream
      .where((event) => !event.remoteTriggered)
      .map((event) => event.changed);

  final BehaviorSubject<({Set<String> changed, bool remoteTriggered})>
  _updatedTagIds = BehaviorSubject();

  Stream<Set<String>> get updatedTagIds =>
      _updatedTagIds.stream.map((event) => event.changed);

  Stream<Set<String>> get locallyUpdatedTagIds => _updatedTagIds.stream
      .where((event) => !event.remoteTriggered)
      .map((event) => event.changed);

  final BehaviorSubject<Set<String>> _deletedScoreIds = BehaviorSubject();

  Stream<Set<String>> get deletedScoreIds => _deletedScoreIds.stream;

  final BehaviorSubject<String> _lastOpenedChanged = BehaviorSubject();

  Stream<String> get lastOpenedChanged => _lastOpenedChanged.stream;

  ScoresRepository({required this._db, required this._thumbnailService});

  List<String> _freshImports = [];

  UnmodifiableListView<String> get freshImports =>
      UnmodifiableListView(_freshImports);

  Future<Score?> getScore(String id) async {
    final result = await _db.managers.scoresTable
        .filter((f) => f.id(id))
        .withReferences(
          (prefetch) => prefetch(
            genresTableRefs: true,
            instrumentsTableRefs: true,
            scoreTagsTableRefs: false,
          ),
        )
        .getSingleOrNull();
    if (result == null) return null;
    final score = result.$1;
    final data = result.$2;

    return Score(
      id: score.id,
      title: score.title,
      composer: score.composer,
      source: score.source,
      sourceLink: score.sourceLink,
      notes: score.notes,
      annotations: score.annotations,
      genres:
          (data.genresTableRefs.prefetchedData ?? [])
              .map((e) => e.genre)
              .toList()
            ..sort(),
      instruments:
          (data.instrumentsTableRefs.prefetchedData ?? [])
              .map((e) => e.instrument)
              .toList()
            ..sort(),
      tags: (await _getScoreTags(score.id)).toList(),
      type: score.type,
      metadataUpdatedAt: score.metadataUpdatedAt.toUtc(),
      fileUpdatedAt: score.fileUpdatedAt.toUtc(),
      fileType: score.fileType,
      file: score.fileDownloaded
          ? await scoreFile(score.id, score.fileType)
          : null,
    );
  }

  Expression<bool> _matchHaving(
    FilterMatchType type,
    Expression<int> matchingCount,
    Expression<int> totalCount,
    int selectedLen,
  ) {
    switch (type) {
      case FilterMatchType.any:
        return matchingCount.isBiggerThanValue(0);
      case FilterMatchType.all:
        return matchingCount.equals(selectedLen);
      case FilterMatchType.exact:
        return matchingCount.equals(selectedLen) &
            totalCount.equals(selectedLen);
    }
  }

  List<Join> _filterJoins({
    required Iterable<String> instruments,
    required Iterable<String> genres,
    required Iterable<String> tagIds,
    required FilterMatchType genreMatch,
    required FilterMatchType instrumentMatch,
    required FilterMatchType tagMatch,
  }) {
    final tagsSubQ = _db.selectOnly(_db.scoreTagsTable).join([]);
    tagsSubQ.addColumns([_db.scoreTagsTable.score]);
    tagsSubQ.groupBy(
      [_db.scoreTagsTable.score],
      having: _matchHaving(
        tagMatch,
        _db.scoreTagsTable.tag.count(
          distinct: true,
          filter: _db.scoreTagsTable.tag.isIn(tagIds),
        ),
        _db.scoreTagsTable.tag.count(distinct: true),
        tagIds.length,
      ),
    );
    final assignedToTags = Subquery(tagsSubQ, 'assigned_to_tags');

    final instrumentsSubQ = _db.selectOnly(_db.instrumentsTable).join([]);
    instrumentsSubQ.addColumns([_db.instrumentsTable.score]);
    instrumentsSubQ.groupBy(
      [_db.instrumentsTable.score],
      having: _matchHaving(
        instrumentMatch,
        _db.instrumentsTable.instrument.count(
          distinct: true,
          filter: _db.instrumentsTable.instrument.isIn(instruments),
        ),
        _db.instrumentsTable.instrument.count(distinct: true),
        instruments.length,
      ),
    );
    final hasInstruments = Subquery(instrumentsSubQ, 'has_instruments');

    final genresSubQ = _db.selectOnly(_db.genresTable).join([]);
    genresSubQ.addColumns([_db.genresTable.score]);
    genresSubQ.groupBy(
      [_db.genresTable.score],
      having: _matchHaving(
        genreMatch,
        _db.genresTable.genre.count(
          distinct: true,
          filter: _db.genresTable.genre.isIn(genres),
        ),
        _db.genresTable.genre.count(distinct: true),
        genres.length,
      ),
    );
    final assignedToGenres = Subquery(genresSubQ, 'assigned_to_genres');

    return [
      if (tagIds.isNotEmpty)
        innerJoin(
          assignedToTags,
          assignedToTags
              .ref(_db.scoreTagsTable.score)
              .equalsExp(_db.scoresTable.id),
          useColumns: false,
        ),
      if (instruments.isNotEmpty)
        innerJoin(
          hasInstruments,
          hasInstruments
              .ref(_db.instrumentsTable.score)
              .equalsExp(_db.scoresTable.id),
          useColumns: false,
        ),
      if (genres.isNotEmpty)
        innerJoin(
          assignedToGenres,
          assignedToGenres
              .ref(_db.genresTable.score)
              .equalsExp(_db.scoresTable.id),
          useColumns: false,
        ),
    ];
  }

  void _applyScoreFilters(
    JoinedSelectStatement q,
    Iterable<String> searchFields,
    String composer,
    String source,
    ScoreType? type,
  ) {
    for (final s in searchFields) {
      q.where(_db.scoresTable.searchText.contains(s));
    }
    if (type != null) {
      q.where(_db.scoresTable.type.equalsValue(type));
    }
    if (composer.isNotEmpty) {
      q.where(_db.scoresTable.composer.equals(composer));
    }
    if (source.isNotEmpty) {
      q.where(_db.scoresTable.source.equals(source));
    }
  }

  Future<int> countScores({
    String filter = "",
    String composer = "",
    String source = "",
    ScoreType? type,
    Iterable<String> instruments = const [],
    Iterable<String> genres = const [],
    Iterable<String> tagIds = const [],
    FilterMatchType genreMatch = FilterMatchType.any,
    FilterMatchType instrumentMatch = FilterMatchType.exact,
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final searchFields = _generateSearchFields(filter);
    final countExpr = _db.scoresTable.id.count(distinct: true);
    final q = _db
        .selectOnly(_db.scoresTable)
        .join(
          _filterJoins(
            instruments: instruments,
            genres: genres,
            tagIds: tagIds,
            genreMatch: genreMatch,
            instrumentMatch: instrumentMatch,
            tagMatch: tagMatch,
          ),
        );
    q.addColumns([countExpr]);
    _applyScoreFilters(q, searchFields, composer, source, type);
    final row = await q.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<List<String>> getScoreIds({
    String filter = "",
    String composer = "",
    String source = "",
    ScoreType? type,
    Iterable<String> instruments = const [],
    Iterable<String> genres = const [],
    Iterable<String> tagIds = const [],
    FilterMatchType genreMatch = FilterMatchType.any,
    FilterMatchType instrumentMatch = FilterMatchType.exact,
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final searchFields = _generateSearchFields(filter);
    final q = _db
        .selectOnly(_db.scoresTable)
        .join(
          _filterJoins(
            instruments: instruments,
            genres: genres,
            tagIds: tagIds,
            genreMatch: genreMatch,
            instrumentMatch: instrumentMatch,
            tagMatch: tagMatch,
          ),
        );
    q.addColumns([_db.scoresTable.id]);
    _applyScoreFilters(q, searchFields, composer, source, type);
    q.orderBy([
      ...searchFields
          .take(3)
          .map(
            (s) => OrderingTerm.asc(
              InstrExpression(
                string: _db.scoresTable.searchText,
                substring: Variable(s),
              ),
            ),
          ),
      OrderingTerm.desc(_db.scoresTable.recentTime),
      OrderingTerm.asc(_db.scoresTable.id),
    ]);
    final rows = await q.get();
    return rows.map((row) => row.read(_db.scoresTable.id)!).toList();
  }

  Future<Iterable<Score>> getScores({
    required int size,
    int offset = 0,
    String filter = "",
    String composer = "",
    String source = "",
    ScoreType? type,
    Iterable<String> instruments = const [],
    Iterable<String> genres = const [],
    Iterable<String> tagIds = const [],
    FilterMatchType genreMatch = FilterMatchType.any,
    FilterMatchType instrumentMatch = FilterMatchType.exact,
    FilterMatchType tagMatch = FilterMatchType.all,
  }) async {
    final searchFields = _generateSearchFields(filter);

    final q = _db
        .select(_db.scoresTable)
        .join(
          _filterJoins(
            instruments: instruments,
            genres: genres,
            tagIds: tagIds,
            genreMatch: genreMatch,
            instrumentMatch: instrumentMatch,
            tagMatch: tagMatch,
          ),
        );
    _applyScoreFilters(q, searchFields, composer, source, type);
    q.orderBy([
      ...searchFields
          .take(3)
          .map(
            (s) => OrderingTerm.asc(
              InstrExpression(
                string: _db.scoresTable.searchText,
                substring: Variable(s),
              ),
            ),
          ),
      OrderingTerm.desc(_db.scoresTable.recentTime),
      OrderingTerm.asc(_db.scoresTable.id),
    ]);
    q.limit(size, offset: offset);

    final scores = (await q.get())
        .map((row) => row.readTable(_db.scoresTable))
        .toList();
    final scoreIds = scores.map((s) => s.id).toList();

    final scoreGenres = await _getScoresGenres(scoreIds);
    final scoreInstruments = await _getScoresInstruments(scoreIds);
    final scoreTags = await _getScoresTags(scoreIds);

    return Future.wait(
      scores.map(
        (s) async => Score(
          id: s.id,
          title: s.title,
          composer: s.composer,
          source: s.source,
          sourceLink: s.sourceLink,
          notes: s.notes,
          annotations: s.annotations,
          genres: scoreGenres[s.id] ?? const [],
          instruments: scoreInstruments[s.id] ?? const [],
          tags: scoreTags[s.id] ?? const [],
          type: s.type,
          metadataUpdatedAt: s.metadataUpdatedAt.toUtc(),
          fileUpdatedAt: s.fileUpdatedAt.toUtc(),
          fileType: s.fileType,
          file: s.fileDownloaded ? await scoreFile(s.id, s.fileType) : null,
        ),
      ),
    );
  }

  Future<Map<String, List<String>>> _getScoresGenres(
    Iterable<String> scoreIds,
  ) async {
    final rows = await (_db.select(
      _db.genresTable,
    )..where((t) => t.score.isIn(scoreIds))).get();

    final result = <String, List<String>>{};
    for (final row in rows) {
      (result[row.score] ??= []).add(row.genre);
    }
    for (final genres in result.values) {
      genres.sort();
    }
    return result;
  }

  Future<Map<String, List<String>>> _getScoresInstruments(
    Iterable<String> scoreIds,
  ) async {
    final rows = await (_db.select(
      _db.instrumentsTable,
    )..where((t) => t.score.isIn(scoreIds))).get();

    final result = <String, List<String>>{};
    for (final row in rows) {
      (result[row.score] ??= []).add(row.instrument);
    }
    for (final instruments in result.values) {
      instruments.sort();
    }
    return result;
  }

  Future<Iterable<Tag>> _getScoreTags(String scoreId) async {
    return (await _db.managers.tagsTable
            .filter((f) => f.scoreTagsTableRefs((f) => f.score.id(scoreId)))
            .orderBy((o) => o.name.asc())
            .get())
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            color: Color(t.color),
            type: t.type,
            updatedAt: t.updatedAt.toUtc(),
          ),
        );
  }

  Future<Map<String, List<Tag>>> _getScoresTags(
    Iterable<String> scoreIds,
  ) async {
    Map<String, List<Tag>> scoreTags = {};

    final tags = await _db.managers.tagsTable
        .filter((f) => f.scoreTagsTableRefs((f) => f.score.id.isIn(scoreIds)))
        .orderBy((o) => o.name.asc())
        .withReferences((prefetch) => prefetch(scoreTagsTableRefs: true))
        .get(distinct: true);
    for (final t in tags) {
      final tag = Tag(
        id: t.$1.id,
        name: t.$1.name,
        color: Color(t.$1.color),
        type: t.$1.type,
        updatedAt: t.$1.updatedAt.toUtc(),
      );
      for (final s
          in t.$2.scoreTagsTableRefs.prefetchedData ?? <ScoreTagsTableData>[]) {
        if (!scoreTags.containsKey(s.score)) {
          scoreTags[s.score] = [tag];
        } else {
          scoreTags[s.score]!.add(tag);
        }
      }
    }

    return scoreTags;
  }

  Future<void> updateScore(
    String scoreId, {
    required String title,
    required String composer,
    required String notes,
  }) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            title: Value(title),
            composer: composer.isNotEmpty ? Value(composer) : const Value(null),
            notes: notes.isNotEmpty ? Value(notes) : const Value(null),
            searchText: Value(generateSearchText([title, composer])),
            metadataUpdatedAt: Value(DateTime.now().toUtc()),
            metadataUploaded: const Value(false),
          ),
        );
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> updateScoreSource(
    String scoreId, {
    required String source,
    required String sourceLink,
  }) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            source: source.isNotEmpty ? Value(source) : const Value(null),
            sourceLink: source.isNotEmpty && sourceLink.isNotEmpty
                ? Value(sourceLink)
                : const Value(null),
            metadataUpdatedAt: Value(DateTime.now().toUtc()),
            metadataUploaded: const Value(false),
          ),
        );
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> bulkEditScoreSource(
    Iterable<String> scoreIds,
    String source,
    String sourceLink,
  ) async {
    if (scoreIds.isEmpty) return;
    await _db.managers.scoresTable
        .filter((f) => f.id.isIn(scoreIds))
        .update(
          (o) => o(
            source: source.isNotEmpty ? Value(source) : const Value(null),
            sourceLink: source.isNotEmpty && sourceLink.isNotEmpty
                ? Value(sourceLink)
                : const Value(null),
            metadataUpdatedAt: Value(DateTime.now().toUtc()),
            metadataUploaded: const Value(false),
          ),
        );
    _updatedScoreIds.add((changed: scoreIds.toSet(), remoteTriggered: false));
  }

  Future<void> bulkEditScoreComposer(
    Iterable<String> scoreIds,
    String composer,
  ) async {
    if (scoreIds.isEmpty) return;
    await _db.transaction(() async {
      final query = _db.selectOnly(_db.scoresTable)
        ..addColumns([_db.scoresTable.id, _db.scoresTable.title])
        ..where(_db.scoresTable.id.isIn(scoreIds));
      final scores = await query
          .map(
            (r) => (
              id: r.read(_db.scoresTable.id)!,
              title: r.read(_db.scoresTable.title)!,
            ),
          )
          .get();

      final now = DateTime.now().toUtc();
      for (final score in scores) {
        await _db.managers.scoresTable
            .filter((f) => f.id(score.id))
            .update(
              (o) => o(
                composer: composer.isNotEmpty
                    ? Value(composer)
                    : const Value(null),
                searchText: Value(generateSearchText([score.title, composer])),
                metadataUpdatedAt: Value(now),
                metadataUploaded: const Value(false),
              ),
            );
      }
    });
    _updatedScoreIds.add((changed: scoreIds.toSet(), remoteTriggered: false));
  }

  Future<void> updateLastOpened(String scoreId) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update((o) => o(lastOpened: Value(DateTime.now().toUtc())));
    _lastOpenedChanged.add(scoreId);
  }

  Future<Map<int, List<Stroke>>> getAnnotations(String scoreId) async {
    final query = _db.selectOnly(_db.scoresTable)
      ..addColumns([_db.scoresTable.annotations])
      ..where(_db.scoresTable.id.equals(scoreId));
    final row = await query.getSingleOrNull();
    return decodeAnnotations(row?.read(_db.scoresTable.annotations));
  }

  Future<void> saveAnnotations(
    String scoreId,
    Map<int, List<Stroke>> pages,
  ) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            annotations: Value(encodeAnnotations(pages)),
            metadataUpdatedAt: Value(DateTime.now().toUtc()),
            metadataUploaded: const Value(false),
          ),
        );
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<Tag> createTag({
    required String name,
    required Color color,
    required TagType type,
  }) async {
    final tag = await _db.managers.tagsTable.createReturning(
      (o) => o(
        id: _db.newId(),
        name: name,
        color: color.toARGB32(),
        type: Value(type),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    _updatedTagIds.add((changed: {tag.id}, remoteTriggered: false));
    return Tag(
      id: tag.id,
      name: tag.name,
      color: Color(tag.color),
      type: tag.type,
      updatedAt: tag.updatedAt.toUtc(),
    );
  }

  Future<List<Tag>> getTags({
    String? filter,
    TagType? type,
    int? size,
    int offset = 0,
    Iterable<String> excludeTagIds = const [],
  }) async {
    final q = _db.select(_db.tagsTable);
    if (filter != null) {
      q.where((tbl) => tbl.name.contains(filter));
    }
    if (type != null) {
      q.where((tbl) => tbl.type.equalsValue(type));
    }
    if (excludeTagIds.isNotEmpty) {
      q.where((tbl) => tbl.id.isNotIn(excludeTagIds));
    }
    if (size != null) {
      q.limit(size, offset: offset);
    }
    q.orderBy([(t) => OrderingTerm.asc(t.name.lower())]);
    final rows = await q.get();
    return rows
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            updatedAt: t.updatedAt.toUtc(),
            color: Color(t.color),
            type: t.type,
          ),
        )
        .toList();
  }

  Future<List<Tag>> getTagsById(Iterable<String> tagIds) async {
    if (tagIds.isEmpty) return [];
    final q = _db.select(_db.tagsTable);
    q.where((tbl) => tbl.id.isIn(tagIds));
    q.orderBy([(t) => OrderingTerm.asc(t.name.lower())]);
    final rows = await q.get();
    return rows
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            updatedAt: t.updatedAt.toUtc(),
            color: Color(t.color),
            type: t.type,
          ),
        )
        .toList();
  }

  Future<void> updateTag(
    String tagId, {
    required String name,
    required Color color,
  }) async {
    await _db.managers.tagsTable
        .filter((f) => f.id(tagId))
        .update(
          (o) => o(
            name: Value(name),
            color: Value(color.toARGB32()),
            updatedAt: Value(DateTime.now().toUtc()),
            uploaded: const Value(false),
          ),
        );
    final affectedScores = await _db.managers.scoreTagsTable
        .filter((f) => f.tag.id(tagId))
        .map((s) => s.score)
        .get();
    _updatedScoreIds.add((
      changed: affectedScores.toSet(),
      remoteTriggered: false,
    ));
    _updatedTagIds.add((changed: {tagId}, remoteTriggered: false));
  }

  Future<void> deleteTag(String tagId) async {
    await _db.transaction(() async {
      final affectedScores = await _db.managers.scoreTagsTable
          .filter((f) => f.tag.id(tagId))
          .map((s) => s.score)
          .get();
      await _db.managers.tagsTable.filter((f) => f.id(tagId)).delete();
      await _db.managers.deletedTagsTable.create(
        (o) => o(tagId: tagId, deletedAt: Value(DateTime.now().toUtc())),
      );
      _updatedScoreIds.add((
        changed: affectedScores.toSet(),
        remoteTriggered: false,
      ));
      _updatedTagIds.add((changed: {tagId}, remoteTriggered: false));
    });
  }

  Future<void> addScoreInstruments(
    String scoreId,
    Iterable<String> instruments,
  ) async {
    await _db.transaction(() async {
      await _db.managers.instrumentsTable.bulkCreate(
        (o) => instruments.map((i) => o(score: scoreId, instrument: i)),
        onConflict: DoNothing(),
      );
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> removeScoreInstrument(String scoreId, String instrument) async {
    await _db.transaction(() async {
      await _db.managers.instrumentsTable
          .filter((f) => f.score.id(scoreId) & f.instrument(instrument))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> addScoreGenre(String scoreId, Iterable<String> genres) async {
    await _db.transaction(() async {
      await _db.managers.genresTable.bulkCreate(
        (o) => genres.map((g) => o(score: scoreId, genre: g)),
        onConflict: DoNothing(),
      );
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> removeScoreGenre(String scoreId, String genre) async {
    await _db.transaction(() async {
      await _db.managers.genresTable
          .filter((f) => f.score.id(scoreId) & f.genre(genre))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> bulkEditScoreTags(
    Iterable<String> scoreIds,
    Iterable<String> addTagIds,
    Iterable<String> removeTagIds,
  ) async {
    if (scoreIds.isEmpty) return;
    await _db.transaction(() async {
      if (addTagIds.isNotEmpty) {
        await _db.managers.scoreTagsTable.bulkCreate(
          (o) =>
              scoreIds.expand((s) => addTagIds.map((t) => o(score: s, tag: t))),
          onConflict: DoNothing(),
        );
      }
      if (removeTagIds.isNotEmpty) {
        await _db.managers.scoreTagsTable
            .filter(
              (f) => f.score.id.isIn(scoreIds) & f.tag.id.isIn(removeTagIds),
            )
            .delete();
      }
      await _db.managers.scoresTable
          .filter((f) => f.id.isIn(scoreIds))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: scoreIds.toSet(), remoteTriggered: false));
  }

  Future<void> bulkEditScoreInstruments(
    Iterable<String> scoreIds,
    Iterable<String> addInstruments,
    Iterable<String> removeInstruments,
  ) async {
    if (scoreIds.isEmpty) return;
    await _db.transaction(() async {
      if (addInstruments.isNotEmpty) {
        await _db.managers.instrumentsTable.bulkCreate(
          (o) => scoreIds.expand(
            (s) => addInstruments.map((i) => o(score: s, instrument: i)),
          ),
          onConflict: DoNothing(),
        );
      }
      if (removeInstruments.isNotEmpty) {
        await _db.managers.instrumentsTable
            .filter(
              (f) =>
                  f.score.id.isIn(scoreIds) &
                  f.instrument.isIn(removeInstruments),
            )
            .delete();
      }
      await _db.managers.scoresTable
          .filter((f) => f.id.isIn(scoreIds))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: scoreIds.toSet(), remoteTriggered: false));
  }

  Future<void> bulkEditScoreGenres(
    Iterable<String> scoreIds,
    Iterable<String> addGenres,
    Iterable<String> removeGenres,
  ) async {
    if (scoreIds.isEmpty) return;
    await _db.transaction(() async {
      if (addGenres.isNotEmpty) {
        await _db.managers.genresTable.bulkCreate(
          (o) => scoreIds.expand(
            (s) => addGenres.map((g) => o(score: s, genre: g)),
          ),
          onConflict: DoNothing(),
        );
      }
      if (removeGenres.isNotEmpty) {
        await _db.managers.genresTable
            .filter(
              (f) => f.score.id.isIn(scoreIds) & f.genre.isIn(removeGenres),
            )
            .delete();
      }
      await _db.managers.scoresTable
          .filter((f) => f.id.isIn(scoreIds))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: scoreIds.toSet(), remoteTriggered: false));
  }

  Future<void> addScoreTags(String scoreId, Iterable<String> tagIds) async {
    await _db.transaction(() async {
      await _db.managers.scoreTagsTable.bulkCreate(
        (o) => tagIds.map((id) => o(score: scoreId, tag: id)),
        onConflict: DoNothing(),
      );
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<void> removeScoreTag(String scoreId, String tagId) async {
    await _db.transaction(() async {
      await _db.managers.scoreTagsTable
          .filter((f) => f.score.id(scoreId) & f.tag.id(tagId))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update(
            (o) => o(
              metadataUpdatedAt: Value(DateTime.now().toUtc()),
              metadataUploaded: const Value(false),
            ),
          );
    });
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<List<Score>> importAll(
    Iterable<XFile> files, {
    ScoreType type = ScoreType.score,
  }) async {
    List<Score> scores = [];
    try {
      for (final f in files) {
        final fileType =
            fileTypeFromMimeType(f.mimeType) ??
            fileTypeFromExtension(path.extension(f.name));
        if (fileType == null) {
          throw InvalidFileTypeException(filePath: f.path);
        }

        final id = _db.newId();
        final title = path.basenameWithoutExtension(f.name);

        await createScoreDir(id);
        final file = await scoreFile(id, fileType);

        await f.saveTo(file.path);

        final now = DateTime.now().toUtc();
        scores.add(
          Score(
            id: id,
            title: title,
            composer: null,
            source: null,
            sourceLink: null,
            notes: null,
            annotations: null,
            genres: const [],
            instruments: const [],
            tags: const [],
            type: type,
            fileUpdatedAt: now,
            metadataUpdatedAt: now,
            fileType: fileType,
            file: file,
          ),
        );
      }

      await _db.managers.scoresTable.bulkCreate(
        (o) => scores.map(
          (s) => o(
            id: s.id,
            title: s.title,
            searchText: generateSearchText([s.title]),
            metadataUpdatedAt: Value(s.metadataUpdatedAt.toUtc()),
            fileUpdatedAt: Value(s.fileUpdatedAt.toUtc()),
            fileDownloaded: true,
            fileType: s.fileType,
            type: Value(s.type),
          ),
        ),
      );
    } catch (_) {
      for (final s in scores) {
        try {
          await s.file?.delete();
        } catch (_) {}
      }
      rethrow;
    }

    _freshImports = List.of(scores.map((s) => s.id));
    _updatedScoreIds.add((
      changed: scores.map((s) => s.id).toSet(),
      remoteTriggered: false,
    ));
    return scores;
  }

  Future<void> updateScoreFile(String scoreId, XFile file) async {
    final score = (await getScore(scoreId))!;

    final fileType =
        fileTypeFromMimeType(file.mimeType) ??
        fileTypeFromExtension(path.extension(file.name));
    if (fileType == null) {
      throw InvalidFileTypeException(filePath: file.path);
    }

    await createScoreDir(scoreId);
    final targetFile = await scoreFile(scoreId, fileType);

    await file.saveTo(targetFile.path);

    if (fileType != score.fileType) {
      try {
        (await scoreFile(score.id, score.fileType)).delete();
      } catch (_) {}
    }

    await _thumbnailService.invalidateThumbnails([scoreId]);

    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            fileUpdatedAt: Value(DateTime.now().toUtc()),
            fileType: Value(fileType),
            fileUploaded: const Value(false),
          ),
        );
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
  }

  Future<List<String>> getInstruments({
    String filter = "",
    int? size,
    int offset = 0,
    Iterable<String> exclude = const [],
  }) async {
    final query = _db.selectOnly(_db.instrumentsTable, distinct: true)
      ..addColumns([_db.instrumentsTable.instrument]);
    if (filter.isNotEmpty) {
      query.where(_db.instrumentsTable.instrument.contains(filter));
    }
    if (exclude.isNotEmpty) {
      query.where(_db.instrumentsTable.instrument.isNotIn(exclude));
    }
    query.orderBy([OrderingTerm.asc(_db.instrumentsTable.instrument.lower())]);
    if (size != null) {
      query.limit(size, offset: offset);
    }
    return await query
        .map((r) => r.read(_db.instrumentsTable.instrument)!)
        .get();
  }

  Future<List<String>> getGenres({
    String filter = "",
    int? size,
    int offset = 0,
    Iterable<String> exclude = const [],
  }) async {
    final query = _db.selectOnly(_db.genresTable, distinct: true)
      ..addColumns([_db.genresTable.genre]);
    if (filter.isNotEmpty) {
      query.where(_db.genresTable.genre.contains(filter));
    }
    if (exclude.isNotEmpty) {
      query.where(_db.genresTable.genre.isNotIn(exclude));
    }
    query.orderBy([OrderingTerm.asc(_db.genresTable.genre.lower())]);
    if (size != null) {
      query.limit(size, offset: offset);
    }
    return await query.map((r) => r.read(_db.genresTable.genre)!).get();
  }

  Future<List<String>> getComposers({
    String filter = "",
    int? size,
    int offset = 0,
  }) async {
    final query = _db.selectOnly(_db.scoresTable, distinct: true)
      ..addColumns([_db.scoresTable.composer]);
    if (filter.isEmpty) {
      query.where(_db.scoresTable.composer.isNotNull());
    } else {
      query.where(
        _db.scoresTable.composer.isNotNull() &
            _db.scoresTable.composer.contains(filter),
      );
    }
    query.orderBy([OrderingTerm.asc(_db.scoresTable.composer.lower())]);
    if (size != null) {
      query.limit(size, offset: offset);
    }
    return await query.map((r) => r.read(_db.scoresTable.composer)!).get();
  }

  Future<List<String>> getSources({
    String filter = "",
    int? size,
    int offset = 0,
  }) async {
    final query = _db.selectOnly(_db.scoresTable, distinct: true)
      ..addColumns([_db.scoresTable.source]);
    if (filter.isEmpty) {
      query.where(_db.scoresTable.source.isNotNull());
    } else {
      query.where(
        _db.scoresTable.source.isNotNull() &
            _db.scoresTable.source.contains(filter),
      );
    }
    query.orderBy([OrderingTerm.asc(_db.scoresTable.source.lower())]);
    if (size != null) {
      query.limit(size, offset: offset);
    }
    return await query.map((r) => r.read(_db.scoresTable.source)!).get();
  }

  void clearFreshImports() {
    _freshImports = [];
  }

  Future<void> deleteScore(String scoreId) async {
    await _db.transaction(() async {
      await _db.managers.scoresTable.filter((f) => f.id(scoreId)).delete();
      await _db.managers.deletedScoresTable.create(
        (o) => o(scoreId: scoreId, deletedAt: Value(DateTime.now().toUtc())),
      );
    });
    await cleanupScoreFilesAfterDelete(scoreId);
    _updatedScoreIds.add((changed: {scoreId}, remoteTriggered: false));
    _deletedScoreIds.add({scoreId});
  }

  Future<void> cleanupScoreFilesAfterDelete(String scoreId) async {
    try {
      final dir = await scoreDir(scoreId);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await _thumbnailService.invalidateThumbnails([scoreId]);
    } catch (e, st) {
      Log.error(
        "Failed to clean up files of deleted score $scoreId",
        e: e,
        st: st,
      );
    }
  }

  Future<void> deleteAll() async {
    await _db.transaction(() async {
      await _db.managers.deletedScoresTable.delete();
      await _db.managers.deletedTagsTable.delete();
      await _db.managers.scoresTable.delete();
      await _db.managers.tagsTable.delete();
      await _db.managers.instrumentsTable.delete();
      await _db.managers.genresTable.delete();
    });
    clearFreshImports();
    _updatedScoreIds.add((changed: {}, remoteTriggered: false));
    _updatedTagIds.add((changed: {}, remoteTriggered: false));
    (await scoresDir).delete(recursive: true);
    _cachedScoresDir = null;
  }

  void remoteChangedTags(Set<String> tagIds) {
    if (tagIds.isEmpty) return;
    _updatedTagIds.add((changed: tagIds, remoteTriggered: true));
  }

  void remoteChangedScores(Set<String> scoreIds) {
    if (scoreIds.isEmpty) return;
    _updatedScoreIds.add((changed: scoreIds, remoteTriggered: true));
  }

  void announceDeletedScores(Set<String> scoreIds) {
    if (scoreIds.isEmpty) return;
    _deletedScoreIds.add(scoreIds);
  }

  Directory? _cachedScoresDir;

  Future<Directory> get scoresDir async {
    if (_cachedScoresDir != null) return SynchronousFuture(_cachedScoresDir!);
    final dir = Directory(
      path.join(
        (await getApplicationSupportDirectory()).absolute.path,
        "scores",
      ),
    );
    await dir.create(recursive: true);
    _cachedScoresDir = dir;
    return dir;
  }

  Future<Directory> scoreDir(String id) async {
    return Directory(path.join((await scoresDir).path, id));
  }

  Future<Directory> createScoreDir(String id) async {
    final dir = await scoreDir(id);
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> scoreFile(String id, FileType fileType) async {
    return File(
      path.join(
        (await scoreDir(id)).path,
        "score${fileTypeToExtension(fileType)}",
      ),
    );
  }

  static final _whitespaceRegex = RegExp(r'\s+');

  static String generateSearchText(Iterable<String?> dataFields) {
    String result = dataFields
        .where((f) => f != null && f.isNotEmpty)
        .map((f) {
          return f!.trim().toLowerCase().replaceAll(_whitespaceRegex, " ");
        })
        .join(" ");
    result = removeDiacritics(result);
    return " $result ";
  }

  Iterable<String> _generateSearchFields(String input) {
    if (input.isEmpty) return const [];
    input = input.trim().toLowerCase().replaceAll(_whitespaceRegex, " ");
    input = removeDiacritics(input);
    return input.split(" ").map((s) => " $s");
  }
}
