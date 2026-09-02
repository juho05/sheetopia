/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'exercise_metadata.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class ExerciseMetadataModel {
  final String? description;
  final String? source;
  final String? sourceLink;
  final String? instrument;
  final int? targetBpm;

  ExerciseMetadataModel({
    required this.description,
    required this.source,
    required this.sourceLink,
    required this.instrument,
    required this.targetBpm,
  });

  factory ExerciseMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseMetadataModelToJson(this);
}
