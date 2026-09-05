// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagModel _$TagModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TagModel', json, ($checkedConvert) {
      final val = TagModel(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        color: $checkedConvert('color', (v) => (v as num).toInt()),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => DateTime.parse(v as String),
        ),
        type: $checkedConvert('type', (v) => _typeFromJson(v as String?)),
      );
      return val;
    });

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
  'type': ?_typeToJson(instance.type),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

TagsModel _$TagsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TagsModel', json, ($checkedConvert) {
      final val = TagsModel(
        tags: $checkedConvert(
          'tags',
          (v) => (v as List<dynamic>)
              .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TagsModelToJson(TagsModel instance) => <String, dynamic>{
  'tags': instance.tags,
};
