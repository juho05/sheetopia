// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_score_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateScoreResultModel _$UpdateScoreResultModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateScoreResultModel', json, ($checkedConvert) {
  final val = UpdateScoreResultModel(
    hasFile: $checkedConvert('hasFile', (v) => v as bool? ?? false),
  );
  return val;
});

Map<String, dynamic> _$UpdateScoreResultModelToJson(
  UpdateScoreResultModel instance,
) => <String, dynamic>{'hasFile': instance.hasFile};
