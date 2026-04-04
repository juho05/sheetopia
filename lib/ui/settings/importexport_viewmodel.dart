/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:io/io.dart';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';

class ImportExportViewModel {
  final SyncRepository _syncRepo;
  final ScoresRepository _scoresRepo;

  ImportExportViewModel({required SyncRepository syncRepo, required ScoresRepository scoresRepo}) : _syncRepo = syncRepo, _scoresRepo = scoresRepo;

  Future<void> deleteLocalData() async {
    await _syncRepo.logout();
    await _scoresRepo.deleteAll();
  }

  Future<bool> export() async {
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
        const XTypeGroup(label: "ZIP", extensions: [".zip"], mimeTypes: ["application/zip"], uniformTypeIdentifiers: ["public.zip-archive"])
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
}