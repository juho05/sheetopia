/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'setlists.g.dart';

@JsonSerializable()
class SetlistModel {
  final String id;
  final String name;

  final List<String> scoreIds;
  final DateTime updatedAt;

  SetlistModel({
    required this.id,
    required this.name,
    required this.scoreIds,
    required this.updatedAt,
  });

  factory SetlistModel.fromJson(Map<String, dynamic> json) =>
      _$SetlistModelFromJson(json);

  Map<String, dynamic> toJson() => _$SetlistModelToJson(this);
}

@JsonSerializable()
class SetlistsModel {
  final List<SetlistModel> setlists;

  SetlistsModel({required this.setlists});

  factory SetlistsModel.fromJson(Map<String, dynamic> json) =>
      _$SetlistsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SetlistsModelToJson(this);
}
