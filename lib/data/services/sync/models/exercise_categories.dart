/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:json_annotation/json_annotation.dart';

part 'exercise_categories.g.dart';

@JsonSerializable()
class ExerciseCategoryModel {
  final String id;
  final String name;
  final int position;
  final DateTime updatedAt;

  ExerciseCategoryModel({
    required this.id,
    required this.name,
    required this.position,
    required this.updatedAt,
  });

  factory ExerciseCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseCategoryModelToJson(this);
}

@JsonSerializable()
class ExerciseCategoriesModel {
  final List<ExerciseCategoryModel> categories;

  ExerciseCategoriesModel({required this.categories});

  factory ExerciseCategoriesModel.fromJson(Map<String, dynamic> json) =>
      _$ExerciseCategoriesModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseCategoriesModelToJson(this);
}
