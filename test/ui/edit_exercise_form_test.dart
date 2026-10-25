/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/practice/edit_exercise_form.dart';
import 'package:sheetopia/ui/practice/edit_exercise_viewmodel.dart';

void main() {
  late Database db;
  late ScoresRepository scoresRepo;
  late PracticeRepository repo;

  setUp(() async {
    db = Database(NativeDatabase.memory());
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

  Future<String> createExercise({String description = ""}) =>
      repo.createExercise(
        name: "Scales",
        description: description,
        instrument: "",
        source: "",
        sourceLink: "",
        tagIds: const [],
      );

  Future<void> pumpForm(WidgetTester tester, String exerciseId) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: scoresRepo),
          Provider<PracticeRepository>.value(value: repo),
          ChangeNotifierProvider(
            create: (context) => EditExerciseViewModel(
              repo: repo,
              scoresRepo: scoresRepo,
              exerciseId: exerciseId,
              separate: false,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<EditExerciseViewModel>(
              builder: (context, viewModel, _) => viewModel.loading
                  ? const SizedBox()
                  : const EditExerciseForm(),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets("the description is always shown", (tester) async {
    await pumpForm(tester, await createExercise());

    expect(find.text("Description"), findsOneWidget);
    expect(find.text("Instrument"), findsOneWidget);
  });

  testWidgets("the source is hidden until added and can be removed", (
    tester,
  ) async {
    final id = await createExercise();
    await repo.updateExerciseSource(id, source: "Hanon", sourceLink: "");
    await pumpForm(tester, id);

    expect(find.text("Source"), findsOneWidget);

    await tester.tap(find.byTooltip("Remove field"));
    await settle(tester);
    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(find.text("Source"), findsNothing);
  });

  testWidgets("a difficulty is added and saved", (tester) async {
    final id = await createExercise();
    await pumpForm(tester, id);

    expect(find.byType(DifficultyDropdown), findsNothing);

    await tester.tap(find.text("Add field"));
    await settle(tester);
    await tester.tap(find.text("Difficulty"));
    await settle(tester);
    await tester.tap(find.byType(DifficultyDropdown));
    await settle(tester);
    await tester.tap(find.text("Hard").last);
    await settle(tester);

    expect((await repo.getExercise(id))!.difficulty, Difficulty.hard);
  });
}
