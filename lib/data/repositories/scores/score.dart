/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class Score {
  final String id;
  final String title;
  final String? composer;
  final String? source;
  final String? sourceLink;
  final String? notes;
  final String? annotations;

  final List<String> genres;
  final List<String> instruments;
  final List<Tag> tags;

  final ScoreType type;

  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;

  final FileType fileType;
  final File? file;

  Score({
    required this.id,
    required this.title,
    required this.composer,
    required this.source,
    required this.sourceLink,
    required this.notes,
    required this.annotations,
    required this.genres,
    required this.instruments,
    required this.tags,
    required this.type,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.fileType,
    required this.file,
  });

  Score copyWith({String? title}) => Score(
    id: id,
    title: title ?? this.title,
    composer: composer,
    source: source,
    sourceLink: sourceLink,
    notes: notes,
    annotations: annotations,
    genres: genres,
    instruments: instruments,
    tags: tags,
    type: type,
    metadataUpdatedAt: metadataUpdatedAt,
    fileUpdatedAt: fileUpdatedAt,
    fileType: fileType,
    file: file,
  );
}
