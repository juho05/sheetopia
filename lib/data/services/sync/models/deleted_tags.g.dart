// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_tags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedTagsModel _$DeletedTagsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedTagsModel', json, ($checkedConvert) {
      final val = DeletedTagsModel(
        tagIds: $checkedConvert(
          'tagIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        deletedTags: $checkedConvert(
          'deletedTags',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => DeletedItemModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeletedTagsModelToJson(DeletedTagsModel instance) =>
    <String, dynamic>{
      'tagIds': instance.tagIds,
      'deletedTags': instance.deletedTags,
    };
