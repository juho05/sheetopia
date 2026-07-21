/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';

enum ImportExportStatus {
  idle, importing, exporting
}

class InvalidFileException implements Exception {
  final String message;

  InvalidFileException(this.message);

  @override
  String toString() {
    return "InvalidFileException: $message";
  }
}

class ImportExportRepository extends ChangeNotifier {
  final ScoresRepository _scoresRepo;
  final Database _db;

  final zipTypeGroup = const XTypeGroup(label: "ZIP", extensions: [".zip"], mimeTypes: ["application/zip"], uniformTypeIdentifiers: ["public.zip-archive"]);

  ImportExportStatus _status = ImportExportStatus.idle;
  ImportExportStatus get status => _status;

  ImportExportRepository({required ScoresRepository scoresRepo, required Database db}) : _scoresRepo = scoresRepo, _db = db;

  Set<String> _changedScores = {};
  Set<String> _changedTags = {};

  Future<bool> import({void Function()? onSelected}) async {
    if (_status != ImportExportStatus.idle) {
      throw Exception("Cannot start export when alreading importing/exporting");
    }
    _status = ImportExportStatus.importing;
    notifyListeners();

    try {
      final XFile? zipFile = await openFile(
        acceptedTypeGroups: <XTypeGroup>[zipTypeGroup],
      );
      if (zipFile == null) return false;
      final extension = path.extension(zipFile.path);
      if (extension != ".zip") {
        throw InvalidFileException("invalid file extension: $extension");
      }

      onSelected?.call();

      final tempDir = await getTemporaryDirectory();
      final dir = await tempDir.createTemp("sheetopia-import-");
      try {
        final result = await compute(_decodeZIPFile, {
          "inputPath": zipFile.path,
          "outputPath": dir.path,
        });

        final tags = result["tags"] as List<TagModel>;
        final scores = result["scores"] as List<ScoreModel>;
        final scoresDir = result["scoresDir"] as String;

        await _importTags(tags);
        await _importScores(scores, scoresDir);
      } finally {
        await dir.delete(recursive: true);
      }
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _changedScores = {};
      _changedTags = {};
      _status = ImportExportStatus.idle;
      notifyListeners();
    }

    return true;
  }

  Future<bool> export() async {
    if (_status != ImportExportStatus.idle) {
      throw Exception("Cannot start export when alreading importing/exporting");
    }
    _status = ImportExportStatus.exporting;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      final dir = await tempDir.createTemp("sheetopia-export-");
      final scoresTargetDir = Directory(path.join(dir.path, "scores"));
      await scoresTargetDir.create();


      try {

        final scoresDir = await _scoresRepo.scoresDir;

        await copyPath(scoresDir.path, scoresTargetDir.path);

        {
          final tags = await _scoresRepo.getTags();
          final tagModels = tags.map((t) => TagModel(
            id: t.id,
            name: t.name,
            color: t.color.toARGB32(),
            updatedAt: t.updatedAt.toUtc(),
          )).toList();
          await compute(_saveTagsJson, {
            "dir": dir.path,
            "tagModels": tagModels,
          });
        }

        {
          final scoreModels = <ScoreModel>[];

          int offset = 0;
          while (true) {
            final scores = await _scoresRepo.getScores(size: 500, offset: offset);
            scoreModels.addAll(scores.map((s) => ScoreModel(
              id: s.id,
              title: s.title,
              fileType: s.fileType,
              fileUpdatedAt: s.fileUpdatedAt,
              metadata: ScoreMetadataModel(
                composer: s.composer,
                genres: s.genres,
                instruments: s.instruments,
                notes: s.notes,
                annotations: s.annotations == null
                    ? {}
                    : jsonDecode(s.annotations!) as Map<String, dynamic>,
              ),
              metadataUpdatedAt: s.metadataUpdatedAt,
              tagIds: s.tags.map((t) => t.id).toList(),
            )));
            if (scores.length < 500) break;
          }

          await compute(_saveScoresJson, {
            "scoreModels": scoreModels,
            "dir": dir.path,
          });
        }

        // create marker file
        await File(path.join(dir.path, ".sheetopia")).create();

        final zipFileDir = await tempDir.createTemp();

        try {
          final datetime = DateTime.now();

          final fileName = "sheetopia-export-${DateFormat("yyyy-MM-dd_HH-mm-ss").format(datetime)}.zip";

          final zipFile = File(path.join(zipFileDir.path, fileName));

          await compute(_createZipFileFromDir, {
            "dir": dir.path,
            "path": zipFile.path,
          });

          await dir.delete(recursive: true);

          if (Platform.isIOS || Platform.isAndroid) {
            // TODO provide an option for android users to save file locally
            final result = await SharePlus.instance.share(ShareParams(
              title: "Export scores",
              fileNameOverrides: [fileName],
              files: [
                XFile(
                  zipFile.path,
                  name: fileName,
                  mimeType: "application/zip",
                )
              ],
              sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
            ));
            return result.status != ShareResultStatus.dismissed;
          }

          final result = await getSaveLocation(suggestedName: path.basename(zipFile.path), acceptedTypeGroups: [
            zipTypeGroup
          ], canCreateDirectories: true);

          if (result == null) {
            return false;
          }

          await zipFile.copy(result.path);
        } finally {
          await zipFileDir.delete(recursive: true);
        }

      } finally {
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
      return true;
    } finally {
      _status = ImportExportStatus.idle;
      notifyListeners();
    }
  }

  Future<void> _importTags(List<TagModel> tags) async {
    for (final t in tags) {
      final result = await _db.managers.tagsTable.createReturningOrNull(
            (o) => o(
          id: t.id,
          name: t.name,
          color: t.color,
          updatedAt: Value(t.updatedAt.toUtc()),
          uploaded: const Value(false),
        ),
        onConflict: DoUpdate.withExcluded(
              (old, excluded) => TagsTableCompanion.custom(
            name: excluded.name,
            color: excluded.color,
            uploaded: excluded.uploaded,
            updatedAt: excluded.updatedAt,
          ),
          where: (old, excluded) =>
              old.updatedAt.isSmallerThan(excluded.updatedAt),
        ),
      );
      if (result != null) {
        _changedTags.add(t.id);
        final affectedScores = await _db.managers.scoreTagsTable
            .filter((f) => f.tag.id(t.id))
            .map((s) => s.score)
            .get();
        _changedScores.addAll(affectedScores);
      }
    }
  }

  Future<void> _importScores(List<ScoreModel> scores, String scoresDir) async {
    for (final s in scores) {
      File? deleteFile;
      await _db.transaction(() async {
        final score = await _db.managers.scoresTable
            .filter((f) => f.id(s.id))
            .getSingleOrNull();

        final metadataChanged =
            score != null &&
                score.metadataUpdatedAt.isBefore(s.metadataUpdatedAt);
        final fileChanged =
            score != null && score.fileUpdatedAt.isBefore(s.fileUpdatedAt);

        if (score == null || fileChanged) {
          final scoreFile = File(
            path.join(
              scoresDir,
              s.id,
              "score${fileTypeToExtension(s.fileType)}",
            ));
          if (!await scoreFile.exists()) {
            throw InvalidFileException("missing score file for ${s.id}");
          }

          final targetScoreFile = await _scoresRepo.scoreFile(s.id, s.fileType);
          await scoreFile.copy(targetScoreFile.path);

          if (score != null && score.fileType != s.fileType) {
            deleteFile = await _scoresRepo.scoreFile(score.id, score.fileType);
          }
        }

        if (score == null) {
          await _db.managers.scoresTable.create(
                (o) => o(
              id: s.id,
              searchText: ScoresRepository.generateSearchText([
                s.title,
                s.metadata.composer,
              ]),
              title: s.title,
              composer: _optionalStringValue(s.metadata.composer),
              notes: _optionalStringValue(s.metadata.notes),
              annotations: _annotationsColumnValue(s.metadata.annotations),
              metadataUploaded: const Value(false),
              metadataUpdatedAt: Value(s.metadataUpdatedAt.toUtc()),
              lastOpened: Value(
                s.metadataUpdatedAt.isAfter(s.fileUpdatedAt)
                    ? s.metadataUpdatedAt.toUtc()
                    : s.fileUpdatedAt.toUtc(),
              ),
              fileType: s.fileType,
              fileUpdatedAt: Value(s.fileUpdatedAt.toUtc()),
              fileDownloaded: true,
              fileUploaded: const Value(false),
            ),
          );
        } else if (metadataChanged || fileChanged) {
          await _db.managers.scoresTable
              .filter((f) => f.id(s.id))
              .update(
                (o) => o(
              title: metadataChanged
                  ? Value(s.title)
                  : const Value.absent(),
              metadataUpdatedAt: metadataChanged
                  ? Value(s.metadataUpdatedAt.toUtc())
                  : const Value.absent(),
              metadataUploaded: metadataChanged
                  ? const Value(false)
                  : const Value.absent(),
              composer: metadataChanged
                  ? _optionalStringValue(s.metadata.composer)
                  : const Value.absent(),
              notes: metadataChanged
                  ? _optionalStringValue(s.metadata.notes)
                  : const Value.absent(),
              annotations: metadataChanged
                  ? _annotationsColumnValue(s.metadata.annotations)
                  : const Value.absent(),
              searchText: metadataChanged
                  ? Value(
                ScoresRepository.generateSearchText([
                  s.title,
                  s.metadata.composer,
                ]),
              )
                  : const Value.absent(),
              fileUpdatedAt: fileChanged
                  ? Value(s.fileUpdatedAt.toUtc())
                  : const Value.absent(),
              fileUploaded: fileChanged
                  ? const Value(false)
                  : const Value.absent(),
              fileDownloaded: fileChanged
                  ? const Value(true)
                  : const Value.absent(),
              fileType: fileChanged
                  ? Value(s.fileType)
                  : const Value.absent(),
            ),
          );
        }
        if (metadataChanged) {
          await _db.managers.scoreTagsTable
              .filter((f) => f.score.id(s.id))
              .delete();
          if (s.metadata.instruments != null) {
            await _db.managers.instrumentsTable
                .filter((f) => f.score.id(s.id))
                .delete();
          }
          if (s.metadata.genres != null) {
            await _db.managers.genresTable
                .filter((f) => f.score.id(s.id))
                .delete();
          }
        }
        if (score == null || metadataChanged) {
          if (s.tagIds.isNotEmpty) {
            await _db.managers.scoreTagsTable.bulkCreate(
                  (o) => s.tagIds.map((t) => o(score: s.id, tag: t)),
            );
          }
          if ((s.metadata.instruments ?? []).isNotEmpty) {
            await _db.managers.instrumentsTable.bulkCreate(
                  (o) => s.metadata.instruments!.map(
                    (i) => o(score: s.id, instrument: i),
              ),
            );
          }
          if ((s.metadata.genres ?? []).isNotEmpty) {
            await _db.managers.genresTable.bulkCreate(
                  (o) => s.metadata.genres!.map((g) => o(score: s.id, genre: g)),
            );
          }
          _changedScores.add(s.id);
        }
      });

      if (deleteFile != null) {
        try {
          await deleteFile!.delete();
        } catch (_) {}
      }
    }
  }

  static Future<void> _saveTagsJson(Map params) async {
    final tagsJson = jsonEncode(params["tagModels"]);
    await File(path.join(params["dir"], "tags.json")).writeAsString(tagsJson, encoding: utf8, flush: true, mode: FileMode.write);
  }

  static Future<void> _saveScoresJson(Map params) async {
    final scoresJson = jsonEncode(params["scoreModels"]);
    await File(path.join(params["dir"], "scores.json")).writeAsString(scoresJson, encoding: utf8, flush: true, mode: FileMode.write);
  }

  static Future<void> _createZipFileFromDir(Map params) async {
    final archive = createArchiveFromDirectory(Directory(params["dir"]), includeDirName: false);

    final outStream = OutputFileStream(params["path"]);

    try {
      ZipEncoder().encodeStream(archive, outStream, autoClose: true, level: DeflateLevel.defaultCompression);
    } finally {
      outStream.close();
    }
  }

  static Future<Map> _decodeZIPFile(Map params) async {
    final inputPath = params["inputPath"];
    final outputPath = params["outputPath"];

    await extractFileToDisk(inputPath, outputPath);

    if (!await File(path.join(outputPath, ".sheetopia")).exists()) {
      throw InvalidFileException("missing .sheetopia marker file");
    }

    try {
      List<TagModel> tags;
      {
        final tagsJson = jsonDecode(await File(path.join(outputPath, "tags.json")).readAsString(encoding: utf8)) as List<dynamic>;
        tags = tagsJson.map((tag) => TagModel.fromJson(tag)).toList();
      }

      List<ScoreModel> scores;
      {
        final scoresJson = jsonDecode(await File(path.join(outputPath, "scores.json")).readAsString(encoding: utf8)) as List<dynamic>;
        scores = scoresJson.map((score) => ScoreModel.fromJson(score)).toList();
      }

      final scoresDir = Directory(path.join(outputPath, "scores"));
      if (!await scoresDir.exists()) {
        throw InvalidFileException("missing scores directory");
      }

      return {
        "scores": scores,
        "tags": tags,
        "scoresDir": scoresDir.path,
      };
    } on Exception catch (e, st) {
      throw InvalidFileException(e.toString());
    }
  }

  Value<String?> _optionalStringValue(String? str) {
    if (str == null) return const Value.absent();
    if (str == "") return const Value(null);
    return Value(str);
  }

  Value<String?> _annotationsColumnValue(Map<String, dynamic>? a) {
    if (a == null) return const Value.absent();
    if (a.isEmpty) return const Value(null);
    return Value(jsonEncode(a));
  }
}