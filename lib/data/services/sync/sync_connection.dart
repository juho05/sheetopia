import 'package:json_annotation/json_annotation.dart';

part 'sync_connection.g.dart';

@JsonSerializable()
class SyncConnection {
  final Uri baseUri;
  final String authKey;

  SyncConnection({required this.baseUri, required this.authKey});

  factory SyncConnection.fromJson(Map<String, dynamic> json) =>
      _$SyncConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$SyncConnectionToJson(this);
}
