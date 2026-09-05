/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';

part 'scores.g.dart';

ScoreType? _typeFromJson(String? name) =>
    name == null ? null : ScoreType.byName(name);

String? _typeToJson(ScoreType? type) => type?.name;

@JsonSerializable()
class ScoreModel {
  final String id;
  final String title;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;
  final FileType fileType;
  final List<String> tagIds;
  final ScoreMetadataModel metadata;

  @JsonKey(includeIfNull: false, fromJson: _typeFromJson, toJson: _typeToJson)
  final ScoreType? type;

  ScoreModel({
    required this.id,
    required this.title,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.fileType,
    required this.tagIds,
    required this.metadata,
    required this.type,
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) =>
      _$ScoreModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreModelToJson(this);
}

@JsonSerializable()
class ScoresModel {
  final List<ScoreModel> scores;

  ScoresModel({required this.scores});

  factory ScoresModel.fromJson(Map<String, dynamic> json) =>
      _$ScoresModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScoresModelToJson(this);
}
