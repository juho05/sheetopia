/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/exercise_metadata.dart';

part 'exercises.g.dart';

@JsonSerializable()
class ExerciseModel {
  final String id;
  final String name;
  final String? categoryId;
  final List<String> tagIds;
  final List<String> scoreIds;
  final ExerciseMetadataModel metadata;
  final DateTime updatedAt;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.tagIds,
    required this.scoreIds,
    required this.metadata,
    required this.updatedAt,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseModelToJson(this);
}

@JsonSerializable()
class ExercisesModel {
  final List<ExerciseModel> exercises;

  ExercisesModel({required this.exercises});

  factory ExercisesModel.fromJson(Map<String, dynamic> json) =>
      _$ExercisesModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExercisesModelToJson(this);
}
