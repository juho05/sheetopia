import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';

part 'scores.g.dart';

@JsonSerializable()
class ScoreModel {
  final String id;
  final String title;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;
  final FileType fileType;
  final List<String> tagIds;
  final ScoreMetadataModel metadata;

  ScoreModel({
    required this.id,
    required this.title,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.fileType,
    required this.tagIds,
    required this.metadata,
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
