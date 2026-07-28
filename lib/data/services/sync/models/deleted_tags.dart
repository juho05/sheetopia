/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/deleted_item.dart';

part 'deleted_tags.g.dart';

@JsonSerializable()
class DeletedTagsModel {
  final List<String> tagIds;

  @JsonKey(defaultValue: <DeletedItemModel>[])
  final List<DeletedItemModel> deletedTags;

  DeletedTagsModel({required this.tagIds, required this.deletedTags});

  factory DeletedTagsModel.fromJson(Map<String, dynamic> json) =>
      _$DeletedTagsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedTagsModelToJson(this);
}
