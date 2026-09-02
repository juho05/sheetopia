// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_categories.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExerciseCategoryModel _$ExerciseCategoryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExerciseCategoryModel', json, ($checkedConvert) {
  final val = ExerciseCategoryModel(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$ExerciseCategoryModelToJson(
  ExerciseCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'position': instance.position,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

ExerciseCategoriesModel _$ExerciseCategoriesModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ExerciseCategoriesModel', json, ($checkedConvert) {
  final val = ExerciseCategoriesModel(
    categories: $checkedConvert(
      'categories',
      (v) => (v as List<dynamic>)
          .map((e) => ExerciseCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ExerciseCategoriesModelToJson(
  ExerciseCategoriesModel instance,
) => <String, dynamic>{'categories': instance.categories};
