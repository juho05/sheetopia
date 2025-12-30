// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthKeyModel _$AuthKeyModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AuthKeyModel', json, ($checkedConvert) {
      final val = AuthKeyModel(
        authKey: $checkedConvert('authKey', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$AuthKeyModelToJson(AuthKeyModel instance) =>
    <String, dynamic>{'authKey': instance.authKey};
