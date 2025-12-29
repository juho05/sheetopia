// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_scores.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedScoresModel _$DeletedScoresModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedScoresModel', json, ($checkedConvert) {
      final val = DeletedScoresModel(
        scoreIds: $checkedConvert(
          'scoreIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DeletedScoresModelToJson(DeletedScoresModel instance) =>
    <String, dynamic>{'scoreIds': instance.scoreIds};
