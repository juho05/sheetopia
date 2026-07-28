/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'deleted_item.g.dart';

@JsonSerializable()
class DeletedItemModel {
  final String id;
  final DateTime deletedAt;

  DeletedItemModel({required this.id, required this.deletedAt});

  factory DeletedItemModel.fromJson(Map<String, dynamic> json) =>
      _$DeletedItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedItemModelToJson(this);
}
