/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
