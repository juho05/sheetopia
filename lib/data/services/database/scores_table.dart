/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';

@TableIndex(name: "search_text_index", columns: {#searchText})
@TableIndex(name: "recent_time_index", columns: {#recentTime})
class ScoresTable extends Table {
  late final id = text()();
  late final title = text()();
  late final composer = text().nullable()();
  late final source = text().nullable()();
  late final sourceLink = text().nullable()();
  late final notes = text().nullable()();
  late final searchText = text()();

  late final recentTime = dateTime().generatedAs(
    CustomExpression(
      "MAX(${lastOpened.name}, ${metadataUpdatedAt.name}, ${fileUpdatedAt.name})",
    ),
  )();

  late final lastOpened = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  late final metadataUpdatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();
  late final fileUpdatedAt = dateTime().clientDefault(
    () => DateTime.now().toUtc(),
  )();

  // non-null means the row was restored by an import and the server has not accepted the restore
  late final writtenAt = dateTime().nullable()();

  late final metadataUploaded = boolean().withDefault(const Constant(false))();
  late final fileUploaded = boolean().withDefault(const Constant(false))();
  late final fileDownloaded = boolean()();

  late final fileType = textEnum<FileType>()();

  late final annotations = text().nullable()();

  late final type = textEnum<ScoreType>().withDefault(
    Constant(ScoreType.score.name),
  )();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  String? get tableName => "scores";
}

enum FileType {
  @JsonValue("pdf")
  pdf,
}

enum ScoreType {
  @JsonValue("score")
  score,
  @JsonValue("exercise")
  exercise,
}

FileType? fileTypeFromExtension(String ext) {
  ext = ext.toLowerCase();
  if (ext == ".pdf") {
    return FileType.pdf;
  }
  return null;
}

FileType? fileTypeFromMimeType(String? mimeType) {
  if (mimeType == null) return null;
  if (mimeType == "application/pdf") {
    return FileType.pdf;
  }
  return null;
}

const _pdfMagicBytes = [0x25, 0x50, 0x44, 0x46, 0x2D];

FileType? fileTypeFromMagicBytes(List<int> bytes) {
  if (_startsWith(bytes, _pdfMagicBytes)) {
    return FileType.pdf;
  }
  return null;
}

int get maxMagicBytesLength => _pdfMagicBytes.length;

bool _startsWith(List<int> bytes, List<int> magic) {
  if (bytes.length < magic.length) return false;
  for (int i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return false;
  }
  return true;
}

String fileTypeToExtension(FileType fileType) {
  return switch (fileType) {
    FileType.pdf => ".pdf",
  };
}
