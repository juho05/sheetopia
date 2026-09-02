/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'practice_routines.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class PracticeRoutineMetadataModel {
  final String? description;

  PracticeRoutineMetadataModel({required this.description});

  factory PracticeRoutineMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRoutineMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRoutineMetadataModelToJson(this);
}

@JsonSerializable()
class PracticeRoutineEntryMetadataModel {
  final String? extraNotes;
  final String? defaultScoreId;

  // milliseconds
  final int? targetDuration;

  PracticeRoutineEntryMetadataModel({
    required this.extraNotes,
    required this.defaultScoreId,
    required this.targetDuration,
  });

  factory PracticeRoutineEntryMetadataModel.fromJson(
    Map<String, dynamic> json,
  ) => _$PracticeRoutineEntryMetadataModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PracticeRoutineEntryMetadataModelToJson(this);
}

@JsonSerializable()
class PracticeRoutineEntryModel {
  final String id;
  final String exerciseId;
  final PracticeRoutineEntryMetadataModel metadata;

  PracticeRoutineEntryModel({
    required this.id,
    required this.exerciseId,
    required this.metadata,
  });

  factory PracticeRoutineEntryModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRoutineEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRoutineEntryModelToJson(this);
}

@JsonSerializable()
class PracticeRoutineModel {
  final String id;
  final String name;
  final PracticeRoutineMetadataModel metadata;
  final List<PracticeRoutineEntryModel> entries;
  final DateTime updatedAt;

  PracticeRoutineModel({
    required this.id,
    required this.name,
    required this.metadata,
    required this.entries,
    required this.updatedAt,
  });

  factory PracticeRoutineModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRoutineModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRoutineModelToJson(this);
}

@JsonSerializable()
class PracticeRoutinesModel {
  final List<PracticeRoutineModel> routines;

  PracticeRoutinesModel({required this.routines});

  factory PracticeRoutinesModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRoutinesModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRoutinesModelToJson(this);
}
