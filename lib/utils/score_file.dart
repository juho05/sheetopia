/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:diacritic/diacritic.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:uuid/uuid.dart';

String suggestedScoreFileName(Score score) {
  var suggestedName = removeDiacritics(score.title);
  suggestedName = suggestedName.replaceAll(RegExp(r'\s'), "_");
  suggestedName = suggestedName.replaceAll(RegExp(r'[^\w-]'), "");
  if (suggestedName.isEmpty) suggestedName = "score";
  suggestedName += fileTypeExtension(score.fileType);
  return suggestedName;
}

Future<Directory> _shareCacheDir() async => Directory(
  path.join((await getTemporaryDirectory()).path, "sheetopia_share"),
);

Future<void> clearShareCache() async {
  try {
    final dir = await _shareCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  } catch (e, st) {
    Log.warn("failed to clear the share cache", e: e, st: st);
  }
}

Future<String> _stagedSharePath(File file, String fileName) async {
  await clearShareCache();
  final dir = Directory(
    path.join((await _shareCacheDir()).path, const Uuid().v4()),
  );
  await dir.create(recursive: true);
  final staged = await file.copy(path.join(dir.path, fileName));
  return staged.path;
}

Future<void> shareScoreFile(Score score, {Rect? sharePositionOrigin}) async {
  if (score.file == null) return;
  final fileName = suggestedScoreFileName(score);
  String sharePath;
  try {
    sharePath = await _stagedSharePath(score.file!, fileName);
  } catch (e, st) {
    Log.warn(
      "failed to stage score file for sharing, sharing it in place",
      e: e,
      st: st,
    );
    sharePath = score.file!.path;
  }
  await SharePlus.instance.share(
    ShareParams(
      title: "Share score file",
      fileNameOverrides: [fileName],
      mailToFallbackEnabled: false,
      sharePositionOrigin: sharePositionOrigin,
      files: [
        XFile(
          sharePath,
          mimeType:
              fileTypeToMimeType(score.fileType) ?? "application/octet-stream",
          name: fileName,
        ),
      ],
    ),
  );
}

Future<bool> exportScoreFile(Score score) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return _exportScoreFileMobile(score);
  }
  if (score.file == null) return false;
  final FileSaveLocation? result = await getSaveLocation(
    suggestedName: suggestedScoreFileName(score),
    acceptedTypeGroups: switch (score.fileType) {
      FileType.pdf => [
        const XTypeGroup(
          label: "PDF",
          extensions: <String>["pdf"],
          mimeTypes: ["application/pdf"],
          uniformTypeIdentifiers: ["com.adobe.pdf"],
        ),
      ],
      final other => [
        XTypeGroup(
          label: other.name,
          extensions: <String>[_saveExtension(other)],
        ),
      ],
    },
  );
  if (result == null) return false;
  await XFile(score.file!.path).saveTo(result.path);
  return true;
}

String _saveExtension(FileType fileType) =>
    fileTypeExtension(fileType).substring(1);

Future<bool> _exportScoreFileMobile(Score score) async {
  if (score.file == null) return false;
  final bytes = await score.file!.readAsBytes();
  final result = await fp.FilePicker.saveFile(
    allowedExtensions: [_saveExtension(score.fileType)],
    type: fp.FileType.custom,
    dialogTitle: "Save score file",
    fileName: suggestedScoreFileName(score),
    bytes: bytes,
  );
  return result != null;
}
