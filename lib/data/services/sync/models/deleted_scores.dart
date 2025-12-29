import 'package:json_annotation/json_annotation.dart';

part 'deleted_scores.g.dart';

@JsonSerializable()
class DeletedScoresModel {
  final List<String> scoreIds;

  DeletedScoresModel({required this.scoreIds});

  factory DeletedScoresModel.fromJson(Map<String, dynamic> json) =>
      _$DeletedScoresModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedScoresModelToJson(this);
}
