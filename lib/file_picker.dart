/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';

import 'data/repositories/scores/scores_repository.dart';

Future<File?> selectScoreFile() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final XFile? file = await openFile(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Import",
    );
    if (file == null) return null;
    return File(file.path);
  }
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: ScoresRepository.scoreFileTypeGroup
        .map((e) => e.extensions)
        .expand<String>((e) => e ?? [])
        .toList(),
    withData: false,
    withReadStream: false,
  );
  if (result == null || result.paths.firstOrNull == null) return null;
  return File(result.paths.first!);
}

Future<List<File>> selectScoreFiles() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final List<XFile> files = await openFiles(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Import",
    );
    return files.map((f) => File(f.path)).toList();
  }
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ScoresRepository.scoreFileTypeGroup
        .map((e) => e.extensions)
        .expand<String>((e) => e ?? [])
        .toList(),
    withData: false,
    withReadStream: false,
  );
  if (result == null || result.paths.firstOrNull == null) return [];
  return result.paths.where((p) => p != null).map((p) => File(p!)).toList();
}
