import 'package:json_annotation/json_annotation.dart';

part 'server_info.g.dart';

@JsonSerializable()
class ServerInfoModel {
  final String server;
  final String serverVersion;
  final String apiVersion;
  final DateTime time;

  ServerInfoModel({
    required this.server,
    required this.serverVersion,
    required this.apiVersion,
    required this.time,
  });

  factory ServerInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServerInfoModelToJson(this);
}
