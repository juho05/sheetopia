// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_sessions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeSessionMetadataModel _$PracticeSessionMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeSessionMetadataModel', json, ($checkedConvert) {
  final val = PracticeSessionMetadataModel(
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$PracticeSessionMetadataModelToJson(
  PracticeSessionMetadataModel instance,
) => <String, dynamic>{'description': instance.description};

PracticeSessionEntryMetadataModel _$PracticeSessionEntryMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeSessionEntryMetadataModel', json, (
  $checkedConvert,
) {
  final val = PracticeSessionEntryMetadataModel(
    duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$PracticeSessionEntryMetadataModelToJson(
  PracticeSessionEntryMetadataModel instance,
) => <String, dynamic>{'duration': instance.duration};

PracticeSessionEntryModel _$PracticeSessionEntryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeSessionEntryModel', json, ($checkedConvert) {
  final val = PracticeSessionEntryModel(
    id: $checkedConvert('id', (v) => v as String),
    exerciseId: $checkedConvert('exerciseId', (v) => v as String),
    routineEntryId: $checkedConvert('routineEntryId', (v) => v as String?),
    metadata: $checkedConvert(
      'metadata',
      (v) =>
          PracticeSessionEntryMetadataModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeSessionEntryModelToJson(
  PracticeSessionEntryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'exerciseId': instance.exerciseId,
  'routineEntryId': instance.routineEntryId,
  'metadata': instance.metadata,
};

PracticeSessionModel _$PracticeSessionModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeSessionModel', json, ($checkedConvert) {
  final val = PracticeSessionModel(
    id: $checkedConvert('id', (v) => v as String),
    startedAt: $checkedConvert('startedAt', (v) => DateTime.parse(v as String)),
    endedAt: $checkedConvert(
      'endedAt',
      (v) => const DateTimeConverter().fromJson(v as String?),
    ),
    routineId: $checkedConvert('routineId', (v) => v as String?),
    metadata: $checkedConvert(
      'metadata',
      (v) => PracticeSessionMetadataModel.fromJson(v as Map<String, dynamic>),
    ),
    entries: $checkedConvert(
      'entries',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                PracticeSessionEntryModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$PracticeSessionModelToJson(
  PracticeSessionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'startedAt': instance.startedAt.toIso8601String(),
  'endedAt': const DateTimeConverter().toJson(instance.endedAt),
  'routineId': instance.routineId,
  'metadata': instance.metadata,
  'entries': instance.entries,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

PracticeSessionsModel _$PracticeSessionsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeSessionsModel', json, ($checkedConvert) {
  final val = PracticeSessionsModel(
    sessions: $checkedConvert(
      'sessions',
      (v) => (v as List<dynamic>)
          .map((e) => PracticeSessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeSessionsModelToJson(
  PracticeSessionsModel instance,
) => <String, dynamic>{'sessions': instance.sessions};
