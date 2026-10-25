// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreMetadataModel _$ScoreMetadataModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoreMetadataModel', json, ($checkedConvert) {
      final val = ScoreMetadataModel(
        composer: $checkedConvert('composer', (v) => v as String?),
        arranger: $checkedConvert('arranger', (v) => v as String?),
        source: $checkedConvert('source', (v) => v as String?),
        sourceLink: $checkedConvert('sourceLink', (v) => v as String?),
        notes: $checkedConvert('notes', (v) => v as String?),
        difficulty: $checkedConvert('difficulty', (v) => (v as num?)?.toInt()),
        instruments: $checkedConvert(
          'instruments',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        genres: $checkedConvert(
          'genres',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        annotations: $checkedConvert(
          'annotations',
          (v) => v as Map<String, dynamic>?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$ScoreMetadataModelToJson(ScoreMetadataModel instance) =>
    <String, dynamic>{
      'composer': instance.composer,
      'arranger': instance.arranger,
      'source': instance.source,
      'sourceLink': instance.sourceLink,
      'notes': instance.notes,
      'difficulty': instance.difficulty,
      'instruments': instance.instruments,
      'genres': instance.genres,
      'annotations': instance.annotations,
    };
