/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'score_metadata.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class ScoreMetadataModel {
  final String? composer;
  final String? notes;
  final List<String>? instruments;
  final List<String>? genres;

  ScoreMetadataModel({
    required this.composer,
    required this.notes,
    required this.instruments,
    required this.genres,
  });

  factory ScoreMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ScoreMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreMetadataModelToJson(this);
}
