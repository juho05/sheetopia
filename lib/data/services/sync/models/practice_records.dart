/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/datetime_converter.dart';

part 'practice_records.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class PracticeRecordMetadataModel {
  // milliseconds
  final int? duration;

  @DateTimeConverter()
  final DateTime? startedAt;

  PracticeRecordMetadataModel({
    required this.duration,
    required this.startedAt,
  });

  factory PracticeRecordMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRecordMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRecordMetadataModelToJson(this);
}

@JsonSerializable()
class PracticeRecordModel {
  final String id;
  final String exerciseId;
  final String? routineId;
  final String? routineEntryId;
  final PracticeRecordMetadataModel metadata;
  final DateTime updatedAt;

  PracticeRecordModel({
    required this.id,
    required this.exerciseId,
    required this.routineId,
    required this.routineEntryId,
    required this.metadata,
    required this.updatedAt,
  });

  factory PracticeRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRecordModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRecordModelToJson(this);
}

@JsonSerializable()
class PracticeRecordsModel {
  final List<PracticeRecordModel> records;

  PracticeRecordsModel({required this.records});

  factory PracticeRecordsModel.fromJson(Map<String, dynamic> json) =>
      _$PracticeRecordsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PracticeRecordsModelToJson(this);
}
