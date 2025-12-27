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
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/instr_expression.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
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
    XTypeGroup(label: "PDF", extensions: <String>["pdf"]),
  ];

  final BehaviorSubject<Set<String>> _updatedScoreIds = BehaviorSubject.seeded(
    {},
  );
  Stream<Set<String>> get updatedScoreIds => _updatedScoreIds.stream;

  final BehaviorSubject<Set<String>> _updatedTagIds = BehaviorSubject.seeded(
    {},
  );
  Stream<Set<String>> get updatedTagIds => _updatedTagIds.stream;

  ScoresRepository({
    required Database db,
    required ThumbnailService thumbnailService,
  }) : _db = db,
       _thumbnailService = thumbnailService;

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
      createdAt: score.createdAt,
      metadataUpdatedAt: score.metadataUpdatedAt,
      fileUpdatedAt: score.fileUpdatedAt,
      fileType: score.fileType,
      file: score.downloaded
          ? await _scoreFile(score.id, score.fileType)
          : null,
    );
  }

  Future<Iterable<Score>> getScores({
    required int size,
    int offset = 0,
    String filter = "",
    String composer = "",
    Iterable<String> instruments = const [],
    Iterable<String> genres = const [],
    Iterable<String> tagIds = const [],
  }) async {
    final searchFields = _generateSearchFields(filter);

    final tagsSubQ = _db.selectOnly(_db.scoreTagsTable).join([]);
    tagsSubQ.addColumns([_db.scoreTagsTable.score]);
    tagsSubQ.where(_db.scoreTagsTable.tag.isIn(tagIds));
    tagsSubQ.groupBy(
      [_db.scoreTagsTable.score],
      having: _db.scoreTagsTable.tag
          .count(distinct: true)
          .equals(tagIds.length),
    );
    final assignedToTags = Subquery(tagsSubQ, 'assigned_to_tags');

    final instrumentsSubQ = _db.selectOnly(_db.instrumentsTable).join([]);
    instrumentsSubQ.addColumns([_db.instrumentsTable.score]);
    instrumentsSubQ.where(_db.instrumentsTable.instrument.isIn(instruments));
    instrumentsSubQ.groupBy(
      [_db.instrumentsTable.score],
      having: _db.instrumentsTable.instrument
          .count(distinct: true)
          .equals(instruments.length),
    );
    final hasInstruments = Subquery(instrumentsSubQ, 'has_instruments');

    final q = _db.select(_db.scoresTable).join([
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
      leftOuterJoin(
        _db.genresTable,
        _db.genresTable.score.equalsExp(_db.scoresTable.id),
      ),
      leftOuterJoin(
        _db.instrumentsTable,
        _db.instrumentsTable.score.equalsExp(_db.scoresTable.id),
      ),
      leftOuterJoin(
        _db.scoreTagsTable,
        _db.scoreTagsTable.score.equalsExp(_db.scoresTable.id),
      ),
    ]);
    if (searchFields.isNotEmpty) {
      for (final s in searchFields) {
        q.where(_db.scoresTable.searchText.contains(s));
      }
    }
    if (genres.isNotEmpty) {
      q.where(_db.genresTable.genre.isIn(genres));
    }
    if (composer.isNotEmpty) {
      q.where(_db.scoresTable.composer.equals(composer));
    }
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
      OrderingTerm.desc(_db.scoresTable.createdAt),
      OrderingTerm.asc(_db.scoresTable.id),
    ]);
    q.limit(size, offset: offset);

    final result = await q.get();

    List<
      ({
        ScoresTableData score,
        SplayTreeSet<String> genres,
        SplayTreeSet<String> instruments,
      })
    >
    scores = [];
    String? lastId;
    for (final row in result) {
      final score = row.readTable(_db.scoresTable);
      final genre = row.readTableOrNull(_db.genresTable);
      final instrument = row.readTableOrNull(_db.instrumentsTable);

      if (lastId != score.id) {
        scores.add((
          score: score,
          genres: SplayTreeSet.of([if (genre != null) genre.genre]),
          instruments: SplayTreeSet.of([
            if (instrument != null) instrument.instrument,
          ]),
        ));
        lastId = score.id;
      } else {
        if (genre != null) {
          scores.last.genres.add(genre.genre);
        }
        if (instrument != null) {
          scores.last.instruments.add(instrument.instrument);
        }
      }
    }

    final tags = await _getScoresTags(scores.map((s) => s.score.id));

    return Future.wait(
      scores.map(
        (s) async => Score(
          id: s.score.id,
          title: s.score.title,
          composer: s.score.composer,
          genres: s.genres.toList(),
          instruments: s.instruments.toList(),
          tags: tags[s.score.id] ?? [],
          createdAt: s.score.createdAt,
          metadataUpdatedAt: s.score.metadataUpdatedAt,
          fileUpdatedAt: s.score.fileUpdatedAt,
          fileType: s.score.fileType,
          file: s.score.downloaded
              ? await _scoreFile(s.score.id, s.score.fileType)
              : null,
        ),
      ),
    );
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
            updatedAt: t.updatedAt,
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
        updatedAt: t.$1.updatedAt,
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
  }) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            title: Value(title),
            composer: composer.isNotEmpty ? Value(composer) : const Value(null),
            searchText: Value(_generateSearchText([title, composer])),
            metadataUpdatedAt: Value(DateTime.now()),
          ),
        );
    _updatedScoreIds.add({scoreId});
  }

  Future<Tag> createTag({required String name, required Color color}) async {
    final tag = await _db.managers.tagsTable.createReturning(
      (o) => o(
        id: _db.newId(),
        name: name,
        color: color.toARGB32(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _updatedTagIds.add({tag.id});
    return Tag(
      id: tag.id,
      name: tag.name,
      color: Color(tag.color),
      updatedAt: tag.updatedAt,
    );
  }

  Future<List<Tag>> getTags({
    String? filter,
    int? size,
    int offset = 0,
    Iterable<String> excludeTagIds = const [],
  }) async {
    final q = _db.select(_db.tagsTable);
    if (filter != null) {
      q.where((tbl) => tbl.name.contains(filter));
    }
    if (excludeTagIds.isNotEmpty) {
      q.where((tbl) => tbl.id.isNotIn(excludeTagIds));
    }
    if (size != null) {
      q.limit(size, offset: offset);
    }
    q.orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await q.get();
    return rows
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            updatedAt: t.updatedAt,
            color: Color(t.color),
          ),
        )
        .toList();
  }

  Future<List<Tag>> getTagsById(Iterable<String> tagIds) async {
    if (tagIds.isEmpty) return [];
    final q = _db.select(_db.tagsTable);
    q.where((tbl) => tbl.id.isIn(tagIds));
    q.orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await q.get();
    return rows
        .map(
          (t) => Tag(
            id: t.id,
            name: t.name,
            updatedAt: t.updatedAt,
            color: Color(t.color),
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
            updatedAt: Value(DateTime.now()),
          ),
        );
    final affectedScores = await _db.managers.scoreTagsTable
        .filter((f) => f.tag.id(tagId))
        .map((s) => s.score)
        .get();
    _updatedScoreIds.add(affectedScores.toSet());
    _updatedTagIds.add({tagId});
  }

  Future<void> deleteTag(String tagId) async {
    final affectedScores = await _db.managers.scoreTagsTable
        .filter((f) => f.tag.id(tagId))
        .map((s) => s.score)
        .get();
    await _db.managers.tagsTable.filter((f) => f.id(tagId)).delete();
    _updatedScoreIds.add(affectedScores.toSet());
    _updatedTagIds.add({tagId});
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
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<void> removeScoreInstrument(String scoreId, String instrument) async {
    await _db.transaction(() async {
      await _db.managers.instrumentsTable
          .filter((f) => f.score.id(scoreId) & f.instrument(instrument))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<void> addScoreGenre(String scoreId, Iterable<String> genres) async {
    await _db.transaction(() async {
      await _db.managers.genresTable.bulkCreate(
        (o) => genres.map((g) => o(score: scoreId, genre: g)),
        onConflict: DoNothing(),
      );
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<void> removeScoreGenre(String scoreId, String genre) async {
    await _db.transaction(() async {
      await _db.managers.genresTable
          .filter((f) => f.score.id(scoreId) & f.genre(genre))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<void> addScoreTags(String scoreId, Iterable<String> tagIds) async {
    await _db.transaction(() async {
      await _db.managers.scoreTagsTable.bulkCreate(
        (o) => tagIds.map((id) => o(score: scoreId, tag: id)),
        onConflict: DoNothing(),
      );
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<void> removeScoreTag(String scoreId, String tagId) async {
    await _db.transaction(() async {
      await _db.managers.scoreTagsTable
          .filter((f) => f.score.id(scoreId) & f.tag.id(tagId))
          .delete();
      await _db.managers.scoresTable
          .filter((f) => f.id(scoreId))
          .update((o) => o(metadataUpdatedAt: Value(DateTime.now())));
    });
    _updatedScoreIds.add({scoreId});
  }

  Future<List<Score>> importAll(Iterable<String> paths) async {
    List<Score> scores = [];
    try {
      for (final p in paths) {
        final fileType = fileTypeFromExtension(path.extension(p));
        if (fileType == null) {
          throw InvalidFileTypeException(filePath: p);
        }

        final id = _db.newId();
        final title = path.basenameWithoutExtension(p);

        final file = await _scoreFile(id, fileType);

        await File(p).copy(file.path);

        final now = DateTime.now();
        scores.add(
          Score(
            id: id,
            title: title,
            composer: null,
            genres: const [],
            instruments: const [],
            tags: const [],
            createdAt: now,
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
            searchText: _generateSearchText([s.title]),
            createdAt: Value(s.createdAt),
            metadataUpdatedAt: Value(s.metadataUpdatedAt),
            fileUpdatedAt: Value(s.fileUpdatedAt),
            downloaded: true,
            fileType: s.fileType,
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
    _updatedScoreIds.add(scores.map((s) => s.id).toSet());
    return scores;
  }

  Future<void> updateScoreFile(String scoreId, String filePath) async {
    final score = (await getScore(scoreId))!;

    final fileType = fileTypeFromExtension(path.extension(filePath));
    if (fileType == null) {
      throw InvalidFileTypeException(filePath: filePath);
    }

    final file = await _scoreFile(scoreId, fileType);

    await File(filePath).copy(file.path);

    if (fileType != score.fileType) {
      try {
        (await _scoreFile(score.id, score.fileType)).delete();
      } catch (_) {}
    }

    await _thumbnailService.invalidateThumbnails([scoreId]);

    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            fileUpdatedAt: Value(DateTime.now()),
            fileType: Value(fileType),
          ),
        );
    _updatedScoreIds.add({scoreId});
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
    query.orderBy([OrderingTerm.asc(_db.instrumentsTable.instrument)]);
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
    query.orderBy([OrderingTerm.asc(_db.genresTable.genre)]);
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
    query.orderBy([OrderingTerm.asc(_db.scoresTable.composer)]);
    if (size != null) {
      query.limit(size, offset: offset);
    }
    return await query.map((r) => r.read(_db.scoresTable.composer)!).get();
  }

  void clearFreshImports() {
    _freshImports = [];
  }

  Future<void> deleteScore(String scoreId) async {
    final score = await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingle();
    await _db.managers.scoresTable.filter((f) => f.id(scoreId)).delete();
    _updatedScoreIds.add({scoreId});
    try {
      (await _scoreFile(scoreId, score.fileType)).delete();
    } catch (_) {}
    await _thumbnailService.invalidateThumbnails([scoreId]);
  }

  Directory? _cachedScoresDir;
  Future<Directory> get _scoresDir async {
    if (_cachedScoresDir != null) return SynchronousFuture(_cachedScoresDir!);
    final dir = Directory(
      path.join(
        (await getApplicationSupportDirectory()).absolute.path,
        "scores",
      ),
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _cachedScoresDir = dir;
    return dir;
  }

  Future<File> _scoreFile(String id, FileType fileType) async {
    return File(
      path.join((await _scoresDir).path, id + fileTypeToExtension(fileType)),
    );
  }

  final _whitespaceRegex = RegExp(r'\s+');

  String _generateSearchText(Iterable<String?> dataFields) {
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
