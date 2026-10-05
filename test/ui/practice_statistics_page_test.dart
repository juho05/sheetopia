/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/duration_bar_chart.dart';
import 'package:sheetopia/ui/practice/practice_statistics_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  // a Wednesday
  final now = DateTime(2026, 3, 11, 12);

  late Database db;
  late PracticeRepository repo;
  late ScoresRepository scoresRepo;

  Future<String> createExercise(String name) => repo.createExercise(
    name: name,
    description: "",
    instrument: "",
    source: "",
    sourceLink: "",
    tagIds: const [],
  );

  Future<void> createRecord(
    String exerciseId,
    DateTime startedAt,
    Duration duration,
  ) => repo.createRecord(
    exerciseId: exerciseId,
    startedAt: startedAt,
    duration: duration,
  );

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = PracticeRepository(db: db, scoresRepo: scoresRepo);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpStatistics(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: "/practice/statistics",
      routes: [
        GoRoute(
          path: "/practice/statistics",
          builder: (context, state) => PracticeStatisticsPage(clock: () => now),
          routes: [
            GoRoute(
              path: "records",
              builder: (context, state) => const Text("records page"),
            ),
            GoRoute(
              path: "exercises",
              builder: (context, state) => const Text("exercises page"),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PracticeRepository>.value(value: repo),
          Provider<ScoresRepository>.value(value: scoresRepo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  DurationBarChart mainChart(WidgetTester tester) =>
      tester.widgetList<DurationBarChart>(find.byType(DurationBarChart)).first;

  testWidgets("without records the period is empty", (tester) async {
    await pumpStatistics(tester);

    expect(find.text("Mar 8 - Mar 14, 2026"), findsOneWidget);
    expect(find.text("0 of 4"), findsOneWidget);
    expect(find.text("Nothing practiced in this period."), findsOneWidget);
    expect(find.text("Time of day"), findsNothing);
  });

  testWidgets("the week is totaled per day", (tester) async {
    final scales = await createExercise("Scales");
    final arpeggios = await createExercise("Arpeggios");
    await createRecord(
      scales,
      DateTime(2026, 3, 9, 10),
      const Duration(minutes: 20),
    );
    await createRecord(
      arpeggios,
      DateTime(2026, 3, 10, 10),
      const Duration(minutes: 30),
    );
    await createRecord(
      scales,
      DateTime(2026, 3, 11, 10),
      const Duration(minutes: 30),
    );
    await createRecord(
      scales,
      DateTime(2026, 3, 1, 10),
      const Duration(minutes: 45),
    );

    await pumpStatistics(tester);

    expect(find.text("1h 20min"), findsOneWidget);
    expect(find.text("20min 0s"), findsOneWidget);
    expect(find.text("3 of 4"), findsOneWidget);
    expect(find.text("3 days"), findsNWidgets(2));
    expect(mainChart(tester).values.map((d) => d.inMinutes), [
      0,
      20,
      30,
      30,
      0,
      0,
      0,
    ]);
    final scalesTop = tester.getTopLeft(find.text("Scales")).dy;
    final arpeggiosTop = tester.getTopLeft(find.text("Arpeggios")).dy;
    expect(scalesTop, lessThan(arpeggiosTop));
  });

  testWidgets("the time frame and resolution are selectable", (tester) async {
    final scales = await createExercise("Scales");
    await createRecord(
      scales,
      DateTime(2026, 3, 2, 10),
      const Duration(minutes: 20),
    );

    await pumpStatistics(tester);
    expect(find.text("Weeks"), findsNothing);

    await tester.tap(find.text("Month"));
    await settle(tester);

    expect(find.text("March 2026"), findsOneWidget);
    expect(mainChart(tester).values, hasLength(31));

    await tester.tap(find.text("Weeks"));
    await settle(tester);

    expect(mainChart(tester).values.map((d) => d.inMinutes), [20, 0, 0, 0, 0]);

    await tester.tap(find.text("Year"));
    await settle(tester);

    expect(find.text("2026"), findsOneWidget);
    expect(mainChart(tester).values, hasLength(53));

    await tester.tap(find.text("Months"));
    await settle(tester);

    expect(mainChart(tester).values, hasLength(12));

    await tester.tap(find.text("Week"));
    await settle(tester);

    expect(find.text("Mar 8 - Mar 14, 2026"), findsOneWidget);
    expect(mainChart(tester).values, hasLength(7));
  });

  testWidgets("earlier periods can be browsed", (tester) async {
    final scales = await createExercise("Scales");
    await createRecord(
      scales,
      DateTime(2026, 3, 3, 10),
      const Duration(minutes: 20),
    );

    await pumpStatistics(tester);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip("Next"),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip("Previous"));
    await settle(tester);

    expect(find.text("Mar 1 - Mar 7, 2026"), findsOneWidget);
    expect(find.text("1 of 7"), findsOneWidget);
    expect(mainChart(tester).values[2], const Duration(minutes: 20));

    await tester.tap(find.byTooltip("Next"));
    await settle(tester);

    expect(find.text("Mar 8 - Mar 14, 2026"), findsOneWidget);
  });

  testWidgets("a month is picked from the period label", (tester) async {
    final scales = await createExercise("Scales");
    await createRecord(
      scales,
      DateTime(2024, 11, 5, 10),
      const Duration(minutes: 20),
    );

    await pumpStatistics(tester);
    await tester.tap(find.text("Month"));
    await settle(tester);

    await tester.tap(find.text("March 2026"));
    await settle(tester);

    expect(find.text("Select month"), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, "Apr")).enabled,
      isFalse,
    );

    await tester.tap(find.byTooltip("Previous year"));
    await tester.tap(find.byTooltip("Previous year"));
    await settle(tester);
    await tester.tap(find.text("Nov"));
    await settle(tester);

    expect(find.text("Select month"), findsNothing);
    expect(find.text("November 2024"), findsOneWidget);
    expect(mainChart(tester).values[4], const Duration(minutes: 20));
  });

  testWidgets("a year is picked from the period label", (tester) async {
    final scales = await createExercise("Scales");
    await createRecord(
      scales,
      DateTime(2019, 11, 5, 10),
      const Duration(minutes: 20),
    );

    await pumpStatistics(tester);
    await tester.tap(find.text("Year"));
    await settle(tester);

    await tester.tap(find.text("2026"));
    await settle(tester);

    expect(find.text("2018"), findsNothing);
    await tester.tap(find.text("2019"));
    await settle(tester);

    expect(find.text("Select year"), findsNothing);
    expect(mainChart(tester).values[10], const Duration(minutes: 20));
  });

  testWidgets("a week is picked from the period label", (tester) async {
    await pumpStatistics(tester);

    await tester.tap(find.text("Mar 8 - Mar 14, 2026"));
    await settle(tester);
    await tester.tap(find.text("3"));
    await tester.tap(find.text("OK"));
    await settle(tester);

    expect(find.text("Mar 1 - Mar 7, 2026"), findsOneWidget);
  });

  testWidgets("the today button returns to the current period", (tester) async {
    await pumpStatistics(tester);
    final today = find.ancestor(
      of: find.byTooltip("Today"),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(today).onPressed, isNull);

    await tester.tap(find.byTooltip("Previous"));
    await tester.tap(find.byTooltip("Previous"));
    await settle(tester);
    expect(find.text("Feb 22 - Feb 28, 2026"), findsOneWidget);

    await tester.tap(find.byTooltip("Today"));
    await settle(tester);

    expect(find.text("Mar 8 - Mar 14, 2026"), findsOneWidget);
    expect(tester.widget<IconButton>(today).onPressed, isNull);
  });

  testWidgets("the today button works from a shifted three month period", (
    tester,
  ) async {
    await pumpStatistics(tester);
    await tester.tap(find.text("3 months"));
    await settle(tester);

    await tester.tap(find.text("Jan - Mar 2026"));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, "Feb"));
    await settle(tester);
    expect(find.text("Dec 2025 - Feb 2026"), findsOneWidget);

    await tester.tap(find.byTooltip("Next"));
    await settle(tester);
    expect(find.text("Mar - May 2026"), findsOneWidget);

    await tester.tap(find.byTooltip("Today"));
    await settle(tester);

    expect(find.text("Jan - Mar 2026"), findsOneWidget);
  });

  testWidgets("tapping a bar shows its total", (tester) async {
    final scales = await createExercise("Scales");
    await createRecord(
      scales,
      DateTime(2026, 3, 8, 10),
      const Duration(minutes: 20),
    );
    await createRecord(
      scales,
      DateTime(2026, 3, 9, 10),
      const Duration(minutes: 40),
    );

    await pumpStatistics(tester);
    expect(find.text("Total"), findsOneWidget);

    final chart = find.byType(DurationBarChart).first;
    final rect = tester.getRect(chart);
    await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
    await settle(tester);

    expect(find.text("Total"), findsNothing);
    expect(find.text("Sun, Mar 8, 2026"), findsOneWidget);
    expect(mainChart(tester).selected, 0);

    await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
    await settle(tester);

    expect(find.text("Total"), findsOneWidget);
  });

  testWidgets("the top exercises card opens all exercises", (tester) async {
    await pumpStatistics(tester);

    await tester.tap(find.text("Top exercises"));
    await tester.pumpAndSettle();

    expect(find.text("exercises page"), findsOneWidget);
  });

  testWidgets("the records page is reachable", (tester) async {
    await pumpStatistics(tester);

    await tester.tap(find.text("Records"));
    await tester.pumpAndSettle();

    expect(find.text("records page"), findsOneWidget);
  });
}
