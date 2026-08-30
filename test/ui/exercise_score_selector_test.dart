/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/practice/exercise_score_selector.dart';
import 'package:sheetopia/ui/score/chrome/play_toolbar.dart';

void main() {
  Score score(String title, {bool downloaded = true}) => Score(
    id: title,
    title: title,
    composer: null,
    source: null,
    sourceLink: null,
    notes: null,
    annotations: null,
    genres: const [],
    instruments: const [],
    tags: const [],
    type: ScoreType.exercise,
    metadataUpdatedAt: DateTime.utc(2026),
    fileUpdatedAt: DateTime.utc(2026),
    fileType: FileType.pdf,
    file: downloaded ? File("$title.pdf") : null,
  );

  Future<void> pumpToolbar(
    WidgetTester tester,
    List<Score> scores, {
    int selectedIndex = 0,
    double width = 400,
    List<Widget> trailing = const [],
    void Function(int index)? onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: width,
              child: PlayToolbar(
                center: ExerciseScoreSelector(
                  scores: scores,
                  selectedIndex: selectedIndex,
                  onSelected: onSelected ?? (index) {},
                ),
                trailing: trailing,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("the selected score can be switched", (tester) async {
    var selected = -1;
    await pumpToolbar(tester, [
      score("First"),
      score("Second"),
    ], onSelected: (index) => selected = index);

    expect(find.text("First"), findsOneWidget);

    await tester.tap(find.text("First"));
    await tester.pumpAndSettle();
    expect(find.text("Select score"), findsOneWidget);

    await tester.tap(find.text("Second"));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text("Select score"), findsNothing);
  });

  testWidgets("scores that are not downloaded cannot be picked", (
    tester,
  ) async {
    await pumpToolbar(tester, [
      score("First"),
      score("Second", downloaded: false),
    ]);

    await tester.tap(find.text("First"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Second"));
    await tester.pumpAndSettle();

    expect(find.text("Select score"), findsOneWidget);
  });

  testWidgets("a single score does not open a selector", (tester) async {
    await pumpToolbar(tester, [score("Only")]);

    await tester.tap(find.text("Only"));
    await tester.pumpAndSettle();

    expect(find.text("Select score"), findsNothing);
  });

  testWidgets("the bar fills the bottom inset with its background", (
    tester,
  ) async {
    const inset = 34.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: inset)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 400,
              child: PlayToolbar(
                center: ExerciseScoreSelector(
                  scores: [score("First"), score("Second")],
                  selectedIndex: 0,
                  onSelected: (index) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(PlayToolbar));
    final title = tester.getRect(find.byType(ExerciseScoreSelector));

    expect(bar.height, greaterThan(PlayToolbar.height + inset));
    expect(title.bottom, lessThanOrEqualTo(bar.bottom - inset));
  });

  testWidgets("the title leaves room for the other buttons", (tester) async {
    await pumpToolbar(
      tester,
      [score("A very long score title that would take up the whole toolbar")],
      trailing: [IconButton(onPressed: () {}, icon: const Icon(Icons.timer))],
    );

    final title = tester.getRect(find.byType(ExerciseScoreSelector));
    final button = tester.getRect(find.byType(IconButton));
    expect(title.width, lessThanOrEqualTo(200));
    expect(button.left, greaterThanOrEqualTo(title.right));
  });
}
