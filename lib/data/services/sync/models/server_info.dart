/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
