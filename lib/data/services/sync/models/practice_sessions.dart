/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/datetime_converter.dart';

part 'practice_sessions.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class PracticeSessionMetadataModel {
  final String? description;

  PracticeSessionMetadataModel({required this.description});

  factory PracticeSessionMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeSessionMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeSessionMetadataModelToJson(this);
}

@JsonSerializable()
class PracticeSessionEntryMetadataModel {
  // milliseconds
  final int? duration;

  PracticeSessionEntryMetadataModel({required this.duration});

  factory PracticeSessionEntryMetadataModel.fromJson(
    Map<String, dynamic> json,
  ) => _$PracticeSessionEntryMetadataModelFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PracticeSessionEntryMetadataModelToJson(this);
}

@JsonSerializable()
class PracticeSessionEntryModel {
  final String id;
  final String exerciseId;
  final String? routineEntryId;
  final PracticeSessionEntryMetadataModel metadata;

  PracticeSessionEntryModel({
    required this.id,
    required this.exerciseId,
    required this.routineEntryId,
    required this.metadata,
  });

  factory PracticeSessionEntryModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeSessionEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeSessionEntryModelToJson(this);
}

@JsonSerializable()
class PracticeSessionModel {
  final String id;
  final DateTime startedAt;

  @DateTimeConverter()
  final DateTime? endedAt;

  final String? routineId;
  final PracticeSessionMetadataModel metadata;
  final List<PracticeSessionEntryModel> entries;
  final DateTime updatedAt;

  PracticeSessionModel({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.routineId,
    required this.metadata,
    required this.entries,
    required this.updatedAt,
  });

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeSessionModelToJson(this);
}

@JsonSerializable()
class PracticeSessionsModel {
  final List<PracticeSessionModel> sessions;

  PracticeSessionsModel({required this.sessions});

  factory PracticeSessionsModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeSessionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeSessionsModelToJson(this);
}
