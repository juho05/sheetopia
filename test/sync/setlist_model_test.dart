/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';

void main() {
  test("setlists.json is a bare array that round-trips", () {
    final models = [
      SetlistModel(
        id: "s1",
        name: "Sunday set",
        scoreIds: const ["a", "b", "a", "gone"],
        updatedAt: DateTime.utc(2026, 7, 21, 12, 30),
      ),
      SetlistModel(
        id: "s2",
        name: "Empty",
        scoreIds: const [],
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    ];

    final decoded = (jsonDecode(jsonEncode(models)) as List<dynamic>)
        .map((e) => SetlistModel.fromJson(e))
        .toList();

    expect(decoded, hasLength(2));
    expect(decoded[0].id, "s1");
    expect(decoded[0].name, "Sunday set");
    expect(decoded[0].scoreIds, ["a", "b", "a", "gone"]);
    expect(decoded[0].updatedAt, DateTime.utc(2026, 7, 21, 12, 30));
    expect(decoded[1].scoreIds, isEmpty);
  });

  test("a malformed entry throws CheckedFromJsonException", () {
    expect(
      () => SetlistModel.fromJson(const {
        "id": "s1",
        "name": "Set",
        "scoreIds": "not a list",
        "updatedAt": "2026-07-21T12:30:00.000Z",
      }),
      throwsA(isA<CheckedFromJsonException>()),
    );
  });
}
