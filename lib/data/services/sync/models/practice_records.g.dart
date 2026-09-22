// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_records.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PracticeRecordMetadataModel _$PracticeRecordMetadataModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRecordMetadataModel', json, ($checkedConvert) {
  final val = PracticeRecordMetadataModel(
    duration: $checkedConvert('duration', (v) => (v as num?)?.toInt()),
    startedAt: $checkedConvert(
      'startedAt',
      (v) => const DateTimeConverter().fromJson(v as String?),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeRecordMetadataModelToJson(
  PracticeRecordMetadataModel instance,
) => <String, dynamic>{
  'duration': instance.duration,
  'startedAt': const DateTimeConverter().toJson(instance.startedAt),
};

PracticeRecordModel _$PracticeRecordModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PracticeRecordModel', json, ($checkedConvert) {
      final val = PracticeRecordModel(
        id: $checkedConvert('id', (v) => v as String),
        exerciseId: $checkedConvert('exerciseId', (v) => v as String),
        routineId: $checkedConvert('routineId', (v) => v as String?),
        routineEntryId: $checkedConvert('routineEntryId', (v) => v as String?),
        metadata: $checkedConvert(
          'metadata',
          (v) =>
              PracticeRecordMetadataModel.fromJson(v as Map<String, dynamic>),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PracticeRecordModelToJson(
  PracticeRecordModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'exerciseId': instance.exerciseId,
  'routineId': instance.routineId,
  'routineEntryId': instance.routineEntryId,
  'metadata': instance.metadata,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

PracticeRecordsModel _$PracticeRecordsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PracticeRecordsModel', json, ($checkedConvert) {
  final val = PracticeRecordsModel(
    records: $checkedConvert(
      'records',
      (v) => (v as List<dynamic>)
          .map((e) => PracticeRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PracticeRecordsModelToJson(
  PracticeRecordsModel instance,
) => <String, dynamic>{'records': instance.records};
