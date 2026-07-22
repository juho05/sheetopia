// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlists.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetlistModel _$SetlistModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetlistModel', json, ($checkedConvert) {
      final val = SetlistModel(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        scoreIds: $checkedConvert(
          'scoreIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SetlistModelToJson(SetlistModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'scoreIds': instance.scoreIds,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

SetlistsModel _$SetlistsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetlistsModel', json, ($checkedConvert) {
      final val = SetlistsModel(
        setlists: $checkedConvert(
          'setlists',
          (v) => (v as List<dynamic>)
              .map((e) => SetlistModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SetlistsModelToJson(SetlistsModel instance) =>
    <String, dynamic>{'setlists': instance.setlists};
