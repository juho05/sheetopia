// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercises.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseModel _$ExerciseModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExerciseModel', json, ($checkedConvert) {
      final val = ExerciseModel(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        categoryId: $checkedConvert('categoryId', (v) => v as String?),
        tagIds: $checkedConvert(
          'tagIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        scoreIds: $checkedConvert(
          'scoreIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        metadata: $checkedConvert(
          'metadata',
          (v) => ExerciseMetadataModel.fromJson(v as Map<String, dynamic>),
        ),
        updatedAt: $checkedConvert(
          'updatedAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExerciseModelToJson(ExerciseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'categoryId': instance.categoryId,
      'tagIds': instance.tagIds,
      'scoreIds': instance.scoreIds,
      'metadata': instance.metadata,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

ExercisesModel _$ExercisesModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExercisesModel', json, ($checkedConvert) {
      final val = ExercisesModel(
        exercises: $checkedConvert(
          'exercises',
          (v) => (v as List<dynamic>)
              .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExercisesModelToJson(ExercisesModel instance) =>
    <String, dynamic>{'exercises': instance.exercises};
