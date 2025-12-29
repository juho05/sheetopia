import 'package:json_annotation/json_annotation.dart';

part 'tags.g.dart';

@JsonSerializable()
class TagModel {
  final String id;
  final String name;
  final int color;
  final DateTime updatedAt;

  TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagModelToJson(this);
}

@JsonSerializable()
class TagsModel {
  final List<TagModel> tags;

  TagsModel({required this.tags});

  factory TagsModel.fromJson(Map<String, dynamic> json) =>
      _$TagsModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagsModelToJson(this);
}
