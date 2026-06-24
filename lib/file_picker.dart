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

Future<XFile?> selectScoreFile() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final XFile? file = await openFile(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Import",
    );
    if (file == null) return null;
    return XFile(file.path);
  }
  PlatformFile? file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ScoresRepository.scoreFileTypeGroup
        .map((e) => e.extensions)
        .expand<String>((e) => e ?? [])
        .toList(),
  );
  return file?.xFile;
}

Future<List<XFile>> selectScoreFiles() async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final List<XFile> files = await openFiles(
      acceptedTypeGroups: ScoresRepository.scoreFileTypeGroup,
      confirmButtonText: "Import",
    );
    return files;
  }
  FilePickerResult? result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ScoresRepository.scoreFileTypeGroup
        .map((e) => e.extensions)
        .expand<String>((e) => e ?? [])
        .toList(),
  );
  return result?.xFiles ?? [];
}
