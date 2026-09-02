// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_items.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedItemsModel _$DeletedItemsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedItemsModel', json, ($checkedConvert) {
      final val = DeletedItemsModel(
        deleted: $checkedConvert(
          'deleted',
          (v) => (v as List<dynamic>)
              .map((e) => DeletedItemModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeletedItemsModelToJson(DeletedItemsModel instance) =>
    <String, dynamic>{'deleted': instance.deleted};
