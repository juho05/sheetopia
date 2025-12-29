// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreMetadataModel _$ScoreMetadataModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoreMetadataModel', json, ($checkedConvert) {
      final val = ScoreMetadataModel(
        composer: $checkedConvert('composer', (v) => v as String?),
        instruments: $checkedConvert(
          'instruments',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        genres: $checkedConvert(
          'genres',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ScoreMetadataModelToJson(ScoreMetadataModel instance) =>
    <String, dynamic>{
      'composer': instance.composer,
      'instruments': instance.instruments,
      'genres': instance.genres,
    };
