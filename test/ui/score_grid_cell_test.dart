/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';

void main() {
  final timestamp = DateTime.utc(2026, 1, 1);

  Score score({required String title, int instruments = 0, int tags = 0}) {
    return Score(
      id: "a",
      title: title,
      composer: "Composer",
      source: "Source",
      sourceLink: "https://example.com",
      notes: null,
      annotations: null,
      genres: const [],
      instruments: List.generate(instruments, (i) => "Instrument $i"),
      tags: List.generate(
        tags,
        (i) => Tag(
          id: "$i",
          name: "Tag $i",
          color: Colors.blue,
          type: TagType.score,
          updatedAt: timestamp,
        ),
      ),
      type: ScoreType.score,
      metadataUpdatedAt: timestamp,
      fileUpdatedAt: timestamp,
      fileType: FileType.pdf,
      file: null,
    );
  }

  Future<void> pumpCell(WidgetTester tester, Score score) async {
    await tester.pumpWidget(
      Provider<ThumbnailService>.value(
        value: ThumbnailService(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: ScoreGridCell(score: score)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets("badge strips scroll without a lazy list", (tester) async {
    await pumpCell(tester, score(title: "Short", instruments: 4, tags: 4));

    expect(find.byType(ListView), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ScoreGridCell),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNWidgets(2),
    );
    expect(find.text("Instrument 0"), findsOneWidget);
    expect(find.text("Tag 3"), findsOneWidget);
  });

  testWidgets("a long title lays out inside the fixed cell size", (
    tester,
  ) async {
    await pumpCell(
      tester,
      score(
        title: "A title that is far too long to fit into a grid cell",
        instruments: 2,
        tags: 2,
      ),
    );

    expect(find.byType(OverflowBox), findsOneWidget);
    expect(
      tester.getSize(find.byType(ScoreGridCell)),
      const Size(ScoreGridCell.width * 1.0, ScoreGridCell.height * 1.0),
    );
  });
}
