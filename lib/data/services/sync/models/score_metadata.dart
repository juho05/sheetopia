import 'package:json_annotation/json_annotation.dart';

part 'score_metadata.g.dart';

/// Fields are never explicitly set to null, always the zero value (e.g. "").
/// That way we can detect whether a field is empty or not supported by
/// the app that uploaded the metadata.
@JsonSerializable()
class ScoreMetadataModel {
  final String? composer;
  final List<String>? instruments;
  final List<String>? genres;

  ScoreMetadataModel({
    required this.composer,
    required this.instruments,
    required this.genres,
  });

  factory ScoreMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ScoreMetadataModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreMetadataModelToJson(this);
}
