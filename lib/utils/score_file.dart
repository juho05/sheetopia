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
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

String suggestedScoreFileName(Score score) {
  var suggestedName = removeDiacritics(score.title);
  suggestedName = suggestedName.replaceAll(RegExp(r'\s'), "_");
  suggestedName = suggestedName.replaceAll(RegExp(r'[^\w-]'), "");
  suggestedName += switch (score.fileType) {
    FileType.pdf => ".pdf",
  };
  return suggestedName;
}

Future<void> shareScoreFile(Score score, {Rect? sharePositionOrigin}) async {
  if (score.file == null) return;
  final fileName = suggestedScoreFileName(score);
  await SharePlus.instance.share(
    ShareParams(
      title: "Share score file",
      fileNameOverrides: [fileName],
      mailToFallbackEnabled: false,
      sharePositionOrigin: sharePositionOrigin,
      files: [
        XFile(
          score.file!.path,
          mimeType: switch (score.fileType) {
            FileType.pdf => "application/pdf",
          },
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
    },
  );
  if (result == null) return false;
  await XFile(score.file!.path).saveTo(result.path);
  return true;
}

Future<bool> _exportScoreFileMobile(Score score) async {
  if (score.file == null) return false;
  final bytes = await score.file!.readAsBytes();
  final result = await fp.FilePicker.saveFile(
    allowedExtensions: ["pdf"],
    type: fp.FileType.custom,
    dialogTitle: "Save score file",
    fileName: suggestedScoreFileName(score),
    bytes: bytes,
  );
  return result != null;
}
