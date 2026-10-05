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
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/exercise_duration_bar.dart';
import 'package:sheetopia/ui/practice/exercise_statistics_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PracticeRepository>.value(value: repo),
          Provider<ScoresRepository>.value(value: scoresRepo),
        ],
        child: MaterialApp(home: ExerciseStatisticsPage(clock: () => now)),
      ),
    );
    await settle(tester);
  }

  List<(String, int)> bars(WidgetTester tester) => [
    for (final bar in tester.widgetList<ExerciseDurationBar>(
      find.byType(ExerciseDurationBar),
    ))
      (bar.name ?? "Deleted exercise", bar.duration.inMinutes),
  ];

  Future<void> createLibrary() async {
    final scales = await createExercise("Scales");
    final arpeggios = await createExercise("Arpeggios");
    await createExercise("Hanon");
    await createRecord(
      scales,
      DateTime(2026, 3, 10, 10),
      const Duration(minutes: 10),
    );
    await createRecord(
      scales,
      DateTime(2026, 3, 11, 10),
      const Duration(minutes: 5),
    );
    await createRecord(
      arpeggios,
      DateTime(2026, 3, 5, 10),
      const Duration(minutes: 20),
    );
    await createRecord(
      arpeggios,
      DateTime(2026, 3, 4, 23),
      const Duration(minutes: 40),
    );
    await createRecord(
      scales,
      DateTime(2025, 1, 1, 10),
      const Duration(minutes: 90),
    );
  }

  testWidgets("without exercises a placeholder is shown", (tester) async {
    await pumpPage(tester);

    expect(find.text("No exercises yet."), findsOneWidget);
  });

  testWidgets("all exercises are listed, most practiced first", (tester) async {
    await createLibrary();

    await pumpPage(tester);

    expect(bars(tester), [("Arpeggios", 60), ("Scales", 15), ("Hanon", 0)]);
    final first = tester.widget<ExerciseDurationBar>(
      find.byType(ExerciseDurationBar).first,
    );
    expect(first.longest, const Duration(minutes: 60));
  });

  testWidgets("the time frame reaches back from today", (tester) async {
    await createLibrary();
    await pumpPage(tester);

    await tester.tap(find.text("7 days"));
    await settle(tester);

    expect(bars(tester), [("Arpeggios", 20), ("Scales", 15), ("Hanon", 0)]);

    await tester.tap(find.text("All"));
    await settle(tester);

    expect(bars(tester), [("Scales", 105), ("Arpeggios", 60), ("Hanon", 0)]);
  });

  testWidgets("the search filters the exercises", (tester) async {
    await createLibrary();
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), "sca");
    await settle(tester);

    expect(bars(tester), [("Scales", 15)]);
    final scales = tester.widget<ExerciseDurationBar>(
      find.byType(ExerciseDurationBar),
    );
    expect(scales.longest, const Duration(minutes: 60));

    await tester.enterText(find.byType(TextField), "nothing");
    await settle(tester);

    expect(find.text("No matching exercises."), findsOneWidget);
  });

  testWidgets("deleted exercises stay listed while practiced", (tester) async {
    await createLibrary();
    final etude = await createExercise("Etude");
    final hymn = await createExercise("Hymn");
    await createRecord(
      etude,
      DateTime(2026, 3, 9, 10),
      const Duration(minutes: 30),
    );
    await createRecord(
      hymn,
      DateTime(2025, 6, 1, 10),
      const Duration(minutes: 30),
    );
    await repo.deleteExercises({etude, hymn});

    await pumpPage(tester);

    expect(bars(tester), [
      ("Arpeggios", 60),
      ("Deleted exercise", 30),
      ("Scales", 15),
      ("Hanon", 0),
    ]);

    await tester.tap(find.text("All"));
    await settle(tester);

    expect(bars(tester), [
      ("Scales", 105),
      ("Arpeggios", 60),
      ("Deleted exercise", 30),
      ("Deleted exercise", 30),
      ("Hanon", 0),
    ]);

    await tester.enterText(find.byType(TextField), "del");
    await settle(tester);

    expect(bars(tester), [("Deleted exercise", 30), ("Deleted exercise", 30)]);

    await tester.enterText(find.byType(TextField), "a");
    await settle(tester);

    expect(bars(tester), [("Scales", 105), ("Arpeggios", 60), ("Hanon", 0)]);
  });

  testWidgets("the name of a deleted exercise is italic", (tester) async {
    final etude = await createExercise("Etude");
    await createExercise("Scales");
    await createRecord(
      etude,
      DateTime(2026, 3, 9, 10),
      const Duration(minutes: 30),
    );
    await repo.deleteExercises({etude});

    await pumpPage(tester);

    FontStyle? styleOf(String text) =>
        tester.widget<Text>(find.text(text)).style?.fontStyle;
    expect(styleOf("Deleted exercise"), FontStyle.italic);
    expect(styleOf("Scales"), isNot(FontStyle.italic));
  });

  testWidgets("more exercises load while scrolling", (tester) async {
    for (var i = 0; i < 120; i++) {
      await createExercise("Exercise ${"$i".padLeft(3, "0")}");
    }
    await pumpPage(tester);

    expect(find.text("Exercise 000"), findsOneWidget);
    expect(find.text("Exercise 119"), findsNothing);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await settle(tester);
    }

    expect(find.text("Exercise 119"), findsOneWidget);
  });
}
