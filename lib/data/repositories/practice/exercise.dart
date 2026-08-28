/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';

class Exercise {
  final String id;
  final String name;
  final String? description;
  final ExerciseCategory? category;
  final String? instrument;
  final List<Tag> tags;
  final String? source;
  final String? sourceLink;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.instrument,
    required this.tags,
    required this.description,
    this.source,
    this.sourceLink,
  });
}
