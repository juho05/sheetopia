// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncConnection _$SyncConnectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SyncConnection', json, ($checkedConvert) {
      final val = SyncConnection(
        baseUri: $checkedConvert('baseUri', (v) => Uri.parse(v as String)),
        authKey: $checkedConvert('authKey', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SyncConnectionToJson(SyncConnection instance) =>
    <String, dynamic>{
      'baseUri': instance.baseUri.toString(),
      'authKey': instance.authKey,
    };
