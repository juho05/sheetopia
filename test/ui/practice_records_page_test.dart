/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/practice_records_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpRecords(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PracticeRepository>.value(value: repo),
          Provider<ScoresRepository>.value(value: scoresRepo),
        ],
        child: const MaterialApp(home: PracticeRecordsPage()),
      ),
    );
    await settle(tester);
  }

  testWidgets("without records a placeholder is shown", (tester) async {
    await pumpRecords(tester);

    expect(find.text("No practice records yet."), findsOneWidget);
  });

  testWidgets("records are listed newest first", (tester) async {
    final scales = await createExercise("Scales");
    final arpeggios = await createExercise("Arpeggios");
    await repo.createRecord(
      exerciseId: scales,
      startedAt: DateTime(2026, 3, 1, 10),
      duration: const Duration(minutes: 5),
    );
    await repo.createRecord(
      exerciseId: arpeggios,
      startedAt: DateTime(2026, 3, 2, 10),
      duration: const Duration(minutes: 7, seconds: 3),
    );

    await pumpRecords(tester);

    final arpeggiosTop = tester.getTopLeft(find.text("Arpeggios")).dy;
    final scalesTop = tester.getTopLeft(find.text("Scales")).dy;
    expect(arpeggiosTop, lessThan(scalesTop));
    expect(find.textContaining("7min 3s"), findsOneWidget);
  });

  testWidgets("a record of a deleted exercise stays listed", (tester) async {
    final exercise = await createExercise("Scales");
    await repo.createRecord(
      exerciseId: exercise,
      startedAt: DateTime(2026, 3, 1, 10),
      duration: const Duration(minutes: 5),
    );
    await repo.deleteExercise(exercise);

    await pumpRecords(tester);

    expect(find.text("Deleted exercise"), findsOneWidget);
  });

  testWidgets("editing a record saves the new duration", (tester) async {
    final exercise = await createExercise("Scales");
    final recordId = await repo.createRecord(
      exerciseId: exercise,
      startedAt: DateTime(2026, 3, 1, 10),
      duration: const Duration(minutes: 5),
    );
    await pumpRecords(tester);

    await tester.tap(find.text("Scales"));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, "Minutes"), "12");
    await tester.pump();
    await tester.tap(find.text("Save"));
    await settle(tester);

    final record = (await repo.getRecord(recordId))!;
    expect(record.duration, const Duration(minutes: 12));
    expect(record.startedAt, DateTime(2026, 3, 1, 10));
    expect(find.textContaining("12min 0s"), findsOneWidget);
  });

  testWidgets("a record may not reach into the next day", (tester) async {
    final exercise = await createExercise("Scales");
    await repo.createRecord(
      exerciseId: exercise,
      startedAt: DateTime(2026, 3, 1, 23, 50),
      duration: const Duration(minutes: 5),
    );
    await pumpRecords(tester);

    await tester.tap(find.text("Scales"));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, "Minutes"), "20");
    await tester.pump();

    expect(find.text("The record must end on the same day"), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, "Save"),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets("deleting a record removes it", (tester) async {
    final exercise = await createExercise("Scales");
    final recordId = await repo.createRecord(
      exerciseId: exercise,
      startedAt: DateTime(2026, 3, 1, 10),
      duration: const Duration(minutes: 5),
    );
    await pumpRecords(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Delete"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(await repo.getRecord(recordId), isNull);
    expect(find.text("No practice records yet."), findsOneWidget);
  });

  testWidgets("a record can be added for an exercise", (tester) async {
    await createExercise("Scales");
    await pumpRecords(tester);

    await tester.tap(find.text("Add record"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Select exercise"));
    await settle(tester);
    await tester.tap(find.text("Scales").last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, "Minutes"), "3");
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, "Add"));
    await settle(tester);

    final records = await repo.getRecords(size: 10);
    expect(records.single.duration, const Duration(minutes: 3));
    expect(find.text("Scales"), findsOneWidget);
  });
}
