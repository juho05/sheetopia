// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scores.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreModel _$ScoreModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoreModel', json, ($checkedConvert) {
      final val = ScoreModel(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        metadataUpdatedAt: $checkedConvert(
          'metadataUpdatedAt',
          (v) => DateTime.parse(v as String),
        ),
        fileUpdatedAt: $checkedConvert(
          'fileUpdatedAt',
          (v) => DateTime.parse(v as String),
        ),
        fileType: $checkedConvert(
          'fileType',
          (v) => $enumDecode(_$FileTypeEnumMap, v),
        ),
        tagIds: $checkedConvert(
          'tagIds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        metadata: $checkedConvert(
          'metadata',
          (v) => ScoreMetadataModel.fromJson(v as Map<String, dynamic>),
        ),
        type: $checkedConvert('type', (v) => _typeFromJson(v as String?)),
      );
      return val;
    });

Map<String, dynamic> _$ScoreModelToJson(ScoreModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'metadataUpdatedAt': instance.metadataUpdatedAt.toIso8601String(),
      'fileUpdatedAt': instance.fileUpdatedAt.toIso8601String(),
      'fileType': _$FileTypeEnumMap[instance.fileType]!,
      'tagIds': instance.tagIds,
      'metadata': instance.metadata,
      'type': ?_typeToJson(instance.type),
    };

const _$FileTypeEnumMap = {FileType.pdf: 'pdf'};

ScoresModel _$ScoresModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoresModel', json, ($checkedConvert) {
      final val = ScoresModel(
        scores: $checkedConvert(
          'scores',
          (v) => (v as List<dynamic>)
              .map((e) => ScoreModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ScoresModelToJson(ScoresModel instance) =>
    <String, dynamic>{'scores': instance.scores};
