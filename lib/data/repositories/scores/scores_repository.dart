import 'dart:collection';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
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
    final score = await _db.managers.scoresTable
        .filter((f) => f.id(id))
        .getSingleOrNull();
    if (score == null) return null;
    return Score(
      id: score.id,
      title: score.title,
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
        .get();
    return Future.wait(
      scores.map(
        (s) async => Score(
          id: s.id,
          title: s.title,
          fileType: s.fileType,
          metadataUpdatedAt: s.metadataUpdatedAt,
          createdAt: s.createdAt,
          fileUpdatedAt: s.fileUpdatedAt,
          file: s.downloaded ? await _scoreFile(s.id, s.fileType) : null,
        ),
      ),
    );
  }

  Future<void> updateScore(String scoreId, {required String title}) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) =>
              o(title: Value(title), metadataUpdatedAt: Value(DateTime.now())),
        );
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
