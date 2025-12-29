// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerInfoModel _$ServerInfoModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ServerInfoModel', json, ($checkedConvert) {
      final val = ServerInfoModel(
        server: $checkedConvert('server', (v) => v as String),
        serverVersion: $checkedConvert('serverVersion', (v) => v as String),
        apiVersion: $checkedConvert('apiVersion', (v) => v as String),
        time: $checkedConvert('time', (v) => DateTime.parse(v as String)),
      );
      return val;
    });

Map<String, dynamic> _$ServerInfoModelToJson(ServerInfoModel instance) =>
    <String, dynamic>{
      'server': instance.server,
      'serverVersion': instance.serverVersion,
      'apiVersion': instance.apiVersion,
      'time': instance.time.toIso8601String(),
    };
