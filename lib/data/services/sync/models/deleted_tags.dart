import 'package:json_annotation/json_annotation.dart';

part 'deleted_tags.g.dart';

@JsonSerializable()
class DeletedTagsModel {
  final List<String> tagIds;

  DeletedTagsModel({required this.tagIds});

  factory DeletedTagsModel.fromJson(Map<String, dynamic> json) =>
      _$DeletedTagsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedTagsModelToJson(this);
}
