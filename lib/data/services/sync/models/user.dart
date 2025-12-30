import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class UserModel {
  final String user;

  UserModel({required this.user});

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
