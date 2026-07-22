// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_setlists.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedSetlistsModel _$DeletedSetlistsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeletedSetlistsModel', json, ($checkedConvert) {
  final val = DeletedSetlistsModel(
    setlistIds: $checkedConvert(
      'setlistIds',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$DeletedSetlistsModelToJson(
  DeletedSetlistsModel instance,
) => <String, dynamic>{'setlistIds': instance.setlistIds};
