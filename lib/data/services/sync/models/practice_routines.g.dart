// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_routines.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeRoutineMetadataModel _$PracticeRoutineMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRoutineMetadataModel', json, ($checkedConvert) {
  final val = PracticeRoutineMetadataModel(
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PracticeRoutineMetadataModelToJson(
  PracticeRoutineMetadataModel instance,
) => <String, dynamic>{'description': instance.description};

PracticeRoutineEntryMetadataModel _$PracticeRoutineEntryMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRoutineEntryMetadataModel', json, (
  $checkedConvert,
) {
  final val = PracticeRoutineEntryMetadataModel(
    extraNotes: $checkedConvert('extraNotes', (v) => v as String?),
    defaultScoreId: $checkedConvert('defaultScoreId', (v) => v as String?),
    targetDuration: $checkedConvert(
      'targetDuration',
      (v) => (v as num?)?.toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeRoutineEntryMetadataModelToJson(
  PracticeRoutineEntryMetadataModel instance,
) => <String, dynamic>{
  'extraNotes': instance.extraNotes,
  'defaultScoreId': instance.defaultScoreId,
  'targetDuration': instance.targetDuration,
};

PracticeRoutineEntryModel _$PracticeRoutineEntryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRoutineEntryModel', json, ($checkedConvert) {
  final val = PracticeRoutineEntryModel(
    id: $checkedConvert('id', (v) => v as String),
    exerciseId: $checkedConvert('exerciseId', (v) => v as String),
    metadata: $checkedConvert(
      'metadata',
      (v) =>
          PracticeRoutineEntryMetadataModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeRoutineEntryModelToJson(
  PracticeRoutineEntryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'exerciseId': instance.exerciseId,
  'metadata': instance.metadata,
};

PracticeRoutineModel _$PracticeRoutineModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRoutineModel', json, ($checkedConvert) {
  final val = PracticeRoutineModel(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    metadata: $checkedConvert(
      'metadata',
      (v) => PracticeRoutineMetadataModel.fromJson(v as Map<String, dynamic>),
    ),
    entries: $checkedConvert(
      'entries',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                PracticeRoutineEntryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$PracticeRoutineModelToJson(
  PracticeRoutineModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'metadata': instance.metadata,
  'entries': instance.entries,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

PracticeRoutinesModel _$PracticeRoutinesModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRoutinesModel', json, ($checkedConvert) {
  final val = PracticeRoutinesModel(
    routines: $checkedConvert(
      'routines',
      (v) => (v as List<dynamic>)
          .map((e) => PracticeRoutineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeRoutinesModelToJson(
  PracticeRoutinesModel instance,
) => <String, dynamic>{'routines': instance.routines};
