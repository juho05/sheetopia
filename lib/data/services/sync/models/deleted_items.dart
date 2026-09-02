/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/deleted_item.dart';

part 'deleted_items.g.dart';

@JsonSerializable()
class DeletedItemsModel {
  final List<DeletedItemModel> deleted;

  DeletedItemsModel({required this.deleted});

  factory DeletedItemsModel.fromJson(Map<String, dynamic> json) =>
      _$DeletedItemsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeletedItemsModelToJson(this);
}
