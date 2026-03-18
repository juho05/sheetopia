// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubTag _$GitHubTagFromJson(Map<String, dynamic> json) => $checkedCreate(
  'GitHubTag',
  json,
  ($checkedConvert) {
    final val = GitHubTag(
      name: $checkedConvert('name', (v) => v as String),
      commit: $checkedConvert(
        'commit',
        (v) => _$recordConvert(
          v,
          ($jsonValue) => (
            sha: $jsonValue['sha'] as String,
            url: $jsonValue['url'] as String,
          ),
        ),
      ),
      zipballUrl: $checkedConvert('zipball_url', (v) => v as String),
      tarballUrl: $checkedConvert('tarball_url', (v) => v as String),
      nodeId: $checkedConvert('node_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'zipballUrl': 'zipball_url',
    'tarballUrl': 'tarball_url',
    'nodeId': 'node_id',
  },
);

Map<String, dynamic> _$GitHubTagToJson(GitHubTag instance) => <String, dynamic>{
  'name': instance.name,
  'commit': <String, dynamic>{
    'sha': instance.commit.sha,
    'url': instance.commit.url,
  },
  'zipball_url': instance.zipballUrl,
  'tarball_url': instance.tarballUrl,
  'node_id': instance.nodeId,
};

$Rec _$recordConvert<$Rec>(Object? value, $Rec Function(Map) convert) =>
    convert(value as Map<String, dynamic>);
