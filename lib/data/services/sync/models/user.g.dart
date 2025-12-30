// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UserModel', json, ($checkedConvert) {
      final val = UserModel(user: $checkedConvert('user', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'user': instance.user,
};
