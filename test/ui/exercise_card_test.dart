/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/exercise_card.dart';
import 'package:sheetopia/ui/practice/exercise_play_page.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  Exercise exercise({
    String name = "Scales",
    String? description,
    ExerciseCategory? category,
    String? instrument,
    List<Tag> tags = const [],
  }) => Exercise(
    id: "e1",
    name: name,
    category: category,
    instrument: instrument,
    tags: tags,
    description: description,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Exercise exercise, {
    bool scoresUnavailable = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ExerciseCard(
          exercise: exercise,
          scoresUnavailable: scoresUnavailable,
        ),
      ),
    ),
  );

  testWidgets("the name and description carry the card", (tester) async {
    await pumpCard(
      tester,
      exercise(name: "Long tones", description: "Hold every note for 8 beats."),
    );

    expect(find.text("Long tones"), findsOneWidget);
    expect(find.text("Hold every note for 8 beats."), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets("a name alone is enough", (tester) async {
    await pumpCard(tester, exercise());

    expect(find.text("Scales"), findsOneWidget);
    expect(find.byType(Divider), findsNothing);
    expect(find.textContaining("downloaded"), findsNothing);
  });

  testWidgets("the metadata is shown around the name", (tester) async {
    await pumpCard(
      tester,
      exercise(
        category: const ExerciseCategory(id: "c1", name: "Warmup"),
        instrument: "Guitar",
        tags: [
          Tag(
            id: "t1",
            name: "Legato",
            color: const Color(0xFF00FF00),
            type: TagType.exercise,
            updatedAt: DateTime.utc(2026),
          ),
        ],
      ),
    );

    expect(find.text("WARMUP"), findsOneWidget);
    expect(find.text("Guitar"), findsOneWidget);
    expect(find.text("Legato"), findsOneWidget);
  });

  testWidgets("scores that are not downloaded are called out", (tester) async {
    await pumpCard(tester, exercise(), scoresUnavailable: true);

    expect(
      find.text("None of these scores are downloaded yet."),
      findsOneWidget,
    );
  });

  group("exercise play page", () {
    late Directory tempDir;
    late Database db;
    late ScoresRepository scoresRepo;
    late PracticeRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("exercise_card_test");
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
      db = Database(NativeDatabase.memory());
      await db.customStatement("PRAGMA foreign_keys = ON");
      scoresRepo = ScoresRepository(
        db: db,
        thumbnailService: ThumbnailService(),
      );
      repo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    });

    tearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });

    Future<void> pumpPage(WidgetTester tester, String exerciseId) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<PracticeRepository>.value(value: repo),
            Provider<ScoresRepository>.value(value: scoresRepo),
          ],
          child: MaterialApp(home: ExercisePlayPage(exerciseId: exerciseId)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("an exercise without scores is played as a card", (
      tester,
    ) async {
      final exerciseId = await repo.createExercise(
        name: "Long tones",
        description: "Hold every note for 8 beats.",
        instrument: "",
        source: "",
        sourceLink: "",
        tagIds: const [],
      );

      await pumpPage(tester, exerciseId);

      expect(find.byType(ExerciseCard), findsOneWidget);
      expect(find.text("Long tones"), findsOneWidget);
      expect(find.text("Hold every note for 8 beats."), findsOneWidget);
      expect(find.textContaining("downloaded"), findsNothing);
    });

    testWidgets("an undownloaded score is called out on the card", (
      tester,
    ) async {
      await db.managers.scoresTable.create(
        (o) => o(
          id: "a",
          title: "Title a",
          searchText: "title a",
          fileDownloaded: false,
          fileType: FileType.pdf,
          type: const Value(ScoreType.exercise),
        ),
      );
      final exerciseId = await repo.createExercise(
        name: "Long tones",
        description: "",
        instrument: "",
        source: "",
        sourceLink: "",
        tagIds: const [],
        scoreIds: const ["a"],
      );

      await pumpPage(tester, exerciseId);

      expect(find.byType(ExerciseCard), findsOneWidget);
      expect(
        find.text("None of these scores are downloaded yet."),
        findsOneWidget,
      );
    });
  });
}
