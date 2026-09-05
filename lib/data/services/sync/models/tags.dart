/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';

part 'tags.g.dart';

TagType? _typeFromJson(String? name) =>
    name == null ? null : TagType.byName(name);

String? _typeToJson(TagType? type) => type?.name;

@JsonSerializable()
class TagModel {
  final String id;
  final String name;
  final int color;

  @JsonKey(includeIfNull: false, fromJson: _typeFromJson, toJson: _typeToJson)
  final TagType? type;

  final DateTime updatedAt;

  TagModel({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
    this.type,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagModelToJson(this);
}

@JsonSerializable()
class TagsModel {
  final List<TagModel> tags;

  TagsModel({required this.tags});

  factory TagsModel.fromJson(Map<String, dynamic> json) =>
      _$TagsModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagsModelToJson(this);
}
