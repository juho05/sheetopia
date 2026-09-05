/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';

void main() {
  Map<String, dynamic> tagJson(Map<String, dynamic> type) => {
    "id": "t1",
    "name": "Tag",
    "color": 1,
    "updatedAt": "2026-01-01T00:00:00.000Z",
    ...type,
  };

  Map<String, dynamic> scoreJson(Map<String, dynamic> type) => {
    "id": "s1",
    "title": "Title",
    "metadataUpdatedAt": "2026-01-01T00:00:00.000Z",
    "fileUpdatedAt": "2026-01-01T00:00:00.000Z",
    "fileType": "pdf",
    "tagIds": <String>[],
    "metadata": <String, dynamic>{},
    ...type,
  };

  // the server reports null for a row that no type aware client has written yet
  test("an explicit null type decodes to null", () {
    expect(TagModel.fromJson(tagJson(const {"type": null})).type, isNull);
    expect(ScoreModel.fromJson(scoreJson(const {"type": null})).type, isNull);
  });

  test("a missing type decodes to null", () {
    expect(TagModel.fromJson(tagJson(const {})).type, isNull);
    expect(ScoreModel.fromJson(scoreJson(const {})).type, isNull);
  });

  test("a type from a newer client is retained", () {
    final tagType = TagModel.fromJson(
      tagJson(const {"type": "from-the-future"}),
    ).type;
    final scoreType = ScoreModel.fromJson(
      scoreJson(const {"type": "from-the-future"}),
    ).type;

    expect(tagType, TagType.byName("from-the-future"));
    expect(tagType, isNot(TagType.score));
    expect(tagType, isNot(TagType.exercise));
    expect(tagType!.isKnown, isFalse);

    expect(scoreType, ScoreType.byName("from-the-future"));
    expect(scoreType, isNot(ScoreType.score));
    expect(scoreType, isNot(ScoreType.exercise));
    expect(scoreType!.isKnown, isFalse);
  });

  test("an unknown type is sent back unchanged", () {
    expect(
      TagModel.fromJson(
        tagJson(const {"type": "from-the-future"}),
      ).toJson()["type"],
      "from-the-future",
    );
    expect(
      ScoreModel.fromJson(
        scoreJson(const {"type": "from-the-future"}),
      ).toJson()["type"],
      "from-the-future",
    );
  });

  test("a known type is applied", () {
    expect(
      TagModel.fromJson(tagJson(const {"type": "exercise"})).type,
      TagType.exercise,
    );
    expect(
      ScoreModel.fromJson(scoreJson(const {"type": "exercise"})).type,
      ScoreType.exercise,
    );
  });
}
