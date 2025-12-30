import 'package:json_annotation/json_annotation.dart';

part 'auth_key.g.dart';

@JsonSerializable()
class AuthKeyModel {
  final String authKey;

  AuthKeyModel({required this.authKey});

  factory AuthKeyModel.fromJson(Map<String, dynamic> json) =>
      _$AuthKeyModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthKeyModelToJson(this);
}
