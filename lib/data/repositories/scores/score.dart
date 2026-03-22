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
  final String? notes;

  final List<String> genres;
  final List<String> instruments;
  final List<Tag> tags;

  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;

  final FileType fileType;
  final File? file;

  Score({
    required this.id,
    required this.title,
    required this.composer,
    required this.notes,
    required this.genres,
    required this.instruments,
    required this.tags,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.fileType,
    required this.file,
  });
}
