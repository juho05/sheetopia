// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedItemModel _$DeletedItemModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedItemModel', json, ($checkedConvert) {
      final val = DeletedItemModel(
        id: $checkedConvert('id', (v) => v as String),
        deletedAt: $checkedConvert(
          'deletedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeletedItemModelToJson(DeletedItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deletedAt': instance.deletedAt.toIso8601String(),
    };
