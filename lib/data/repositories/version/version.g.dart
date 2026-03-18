// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Version _$VersionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Version', json, ($checkedConvert) {
      final val = Version(
        major: $checkedConvert('major', (v) => (v as num).toInt()),
        minor: $checkedConvert('minor', (v) => (v as num?)?.toInt() ?? 0),
        patch: $checkedConvert('patch', (v) => (v as num?)?.toInt() ?? 0),
        isFullVersion: $checkedConvert(
          'isFullVersion',
          (v) => v as bool? ?? true,
        ),
      );
      return val;
    });

Map<String, dynamic> _$VersionToJson(Version instance) => <String, dynamic>{
  'major': instance.major,
  'minor': instance.minor,
  'patch': instance.patch,
  'isFullVersion': instance.isFullVersion,
};
