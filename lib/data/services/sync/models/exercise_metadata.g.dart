// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseMetadataModel _$ExerciseMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExerciseMetadataModel', json, ($checkedConvert) {
  final val = ExerciseMetadataModel(
    description: $checkedConvert('description', (v) => v as String?),
    source: $checkedConvert('source', (v) => v as String?),
    sourceLink: $checkedConvert('sourceLink', (v) => v as String?),
    instrument: $checkedConvert('instrument', (v) => v as String?),
    targetBpm: $checkedConvert('targetBpm', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$ExerciseMetadataModelToJson(
  ExerciseMetadataModel instance,
) => <String, dynamic>{
  'description': instance.description,
  'source': instance.source,
  'sourceLink': instance.sourceLink,
  'instrument': instance.instrument,
  'targetBpm': instance.targetBpm,
};
