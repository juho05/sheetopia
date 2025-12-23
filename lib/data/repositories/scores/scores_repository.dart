import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

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

  static const List<XTypeGroup> scoreFileTypeGroup = [
    XTypeGroup(label: "PDF", extensions: <String>["pdf"]),
  ];

  final BehaviorSubject<Iterable<String>> _updatedScoreIds =
      BehaviorSubject.seeded([]);
  Stream<Iterable<String>> get updatedScoreIds => _updatedScoreIds.stream;

  ScoresRepository({required Database db}) : _db = db;

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
            scoreTagsTableRefs: true,
          ),
        )
        .getSingleOrNull();
    if (result == null) return null;
    final score = result.$1;
    final data = result.$2;

    final tags =
        (await _db.managers.tagsTable
                .filter(
                  (f) => f.scoreTagsTableRefs((f) => f.score.id(score.id)),
                )
                .orderBy((o) => o.name.asc())
                .get())
            .map(
              (t) => Tag(
                id: t.id,
                name: t.name,
                color: Color(t.color),
                updatedAt: t.updatedAt,
              ),
            )
            .toList();

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
      tags: tags,
      createdAt: score.createdAt,
      metadataUpdatedAt: score.metadataUpdatedAt,
      fileUpdatedAt: score.fileUpdatedAt,
      fileType: score.fileType,
      file: score.downloaded
          ? await _scoreFile(score.id, score.fileType)
          : null,
    );
  }

  Future<List<Score>> getAllScores() async {
    final scores = await _db.managers.scoresTable
        .orderBy((o) => o.createdAt.desc())
        .withReferences(
          (prefetch) => prefetch(
            genresTableRefs: true,
            instrumentsTableRefs: true,
            scoreTagsTableRefs: false,
          ),
        )
        .get();

    Map<String, List<Tag>> scoreTags = {};

    final tags = await _db.managers.tagsTable
        .orderBy((o) => o.name.asc())
        .withReferences((prefetch) => prefetch(scoreTagsTableRefs: true))
        .get();
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

    return Future.wait(
      scores.map(
        (s) async => Score(
          id: s.$1.id,
          title: s.$1.title,
          composer: s.$1.composer,
          genres:
              (s.$2.genresTableRefs.prefetchedData ?? [])
                  .map((e) => e.genre)
                  .toList()
                ..sort(),
          instruments:
              (s.$2.instrumentsTableRefs.prefetchedData ?? [])
                  .map((e) => e.instrument)
                  .toList()
                ..sort(),
          tags: scoreTags[s.$1.id] ?? [],
          fileType: s.$1.fileType,
          metadataUpdatedAt: s.$1.metadataUpdatedAt,
          createdAt: s.$1.createdAt,
          fileUpdatedAt: s.$1.fileUpdatedAt,
          file: s.$1.downloaded
              ? await _scoreFile(s.$1.id, s.$1.fileType)
              : null,
        ),
      ),
    );
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
            metadataUpdatedAt: Value(DateTime.now()),
          ),
        );
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add([scoreId]);
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
    _updatedScoreIds.add(scores.map((s) => s.id));
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

    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            fileUpdatedAt: Value(DateTime.now()),
            fileType: Value(fileType),
          ),
        );
    _updatedScoreIds.add([scoreId]);
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

  Future<void> deleteScore(String scoreId) async {
    await _db.managers.scoresTable.filter((f) => f.id(scoreId)).delete();
    _updatedScoreIds.add([]);
  }
}
