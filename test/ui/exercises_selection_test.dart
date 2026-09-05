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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/selection/clear_selection_button.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/practice/exercises_page.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;
  late ScoresRepository scoresRepo;

  Future<void> createExercise(String name) async {
    await repo.createExercise(
      name: name,
      description: "",
      instrument: "",
      source: "",
      sourceLink: "",
      tagIds: const [],
    );
  }

  Future<void> createExercises(int count) async {
    for (var i = 0; i < count; i++) {
      await createExercise("Exercise $i");
    }
  }

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

  Future<void> pumpExercises(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: "/", builder: (context, state) => const ExercisesPage()),
        GoRoute(
          path: "/practice/exercises/:id",
          builder: (context, state) => const Text("exercise page"),
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
    await tester.pump();
    await settle(tester);
  }

  Finder tileOf(String name) => find
      .ancestor(of: find.text(name), matching: find.byType(RoundedListTile))
      .first;

  Future<void> tapExercise(
    WidgetTester tester,
    String name, {
    LogicalKeyboardKey? modifier,
  }) async {
    if (modifier != null) await tester.sendKeyDownEvent(modifier);
    await tester.tap(tileOf(name));
    if (modifier != null) await tester.sendKeyUpEvent(modifier);
    await settle(tester);
  }

  Future<void> longPressExercise(WidgetTester tester, String name) async {
    await tester.longPress(tileOf(name));
    await settle(tester);
  }

  Future<void> pressSelectAll(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await settle(tester);
  }

  testWidgets("a long press starts the selection", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("Exercises"), findsNothing);
  });

  testWidgets("the selection icon replaces the exercise icon", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    expect(find.byIcon(Symbols.exercise), findsNWidgets(3));

    await longPressExercise(tester, "Exercise 1");

    expect(find.byIcon(Symbols.exercise), findsNothing);
    expect(find.byIcon(Symbols.check), findsOneWidget);
    expect(find.byIcon(Symbols.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets("ctrl+click starts the selection instead of opening", (
    tester,
  ) async {
    await createExercises(3);
    await pumpExercises(tester);

    await tapExercise(
      tester,
      "Exercise 1",
      modifier: LogicalKeyboardKey.control,
    );

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("exercise page"), findsNothing);
  });

  testWidgets("a tap opens the exercise while not selecting", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    await tapExercise(tester, "Exercise 1");

    expect(find.text("exercise page"), findsOneWidget);
  });

  testWidgets("a tap toggles the exercise while selecting", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 0");
    await tapExercise(tester, "Exercise 1");

    expect(find.text("2 selected"), findsOneWidget);

    await tapExercise(tester, "Exercise 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("exercise page"), findsNothing);
  });

  testWidgets("shift+click selects the range after the anchor", (tester) async {
    await createExercises(5);
    await pumpExercises(tester);

    await tapExercise(
      tester,
      "Exercise 1",
      modifier: LogicalKeyboardKey.control,
    );
    await tapExercise(
      tester,
      "Exercise 3",
      modifier: LogicalKeyboardKey.shiftLeft,
    );

    expect(find.text("3 selected"), findsOneWidget);
    expect(find.byIcon(Symbols.check), findsNWidgets(3));
  });

  testWidgets("shift+click without a selection selects a single exercise", (
    tester,
  ) async {
    await createExercises(5);
    await pumpExercises(tester);

    await tapExercise(
      tester,
      "Exercise 2",
      modifier: LogicalKeyboardKey.shiftLeft,
    );

    expect(find.text("1 selected"), findsOneWidget);
  });

  testWidgets("ctrl+a selects every exercise", (tester) async {
    await createExercises(5);
    await pumpExercises(tester);

    await pressSelectAll(tester);

    expect(find.text("5 selected"), findsOneWidget);
  });

  testWidgets("ctrl+a only selects the exercises matching the filter", (
    tester,
  ) async {
    await createExercise("Bends");
    await createExercise("Chromatic");
    await pumpExercises(tester);

    await tester.enterText(find.byType(SearchInput), "bends");
    await settle(tester);
    // a focused search field owns ctrl+a for its own content
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);
    await pressSelectAll(tester);

    expect(find.text("1 selected"), findsOneWidget);
  });

  testWidgets("escape clears the selection", (tester) async {
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 1");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    expect(find.text("Exercises"), findsOneWidget);
    expect(find.byIcon(Symbols.exercise), findsNWidgets(3));
  });

  testWidgets("the clear button replaces the back button", (tester) async {
    await createExercises(3);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.push("/practice/exercises"),
                child: const Text("open exercises"),
              ),
            ),
          ),
        ),
        GoRoute(
          path: "/practice/exercises",
          builder: (context, state) => const ExercisesPage(),
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
    await tester.tap(find.text("open exercises"));
    await settle(tester);

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(ClearSelectionButton), findsNothing);

    await longPressExercise(tester, "Exercise 1");

    expect(find.byType(BackButton), findsNothing);
    expect(find.byType(ClearSelectionButton), findsOneWidget);

    await tester.tap(find.byType(ClearSelectionButton));
    await settle(tester);

    expect(find.text("Exercises"), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets("the select all button toggles the whole selection", (
    tester,
  ) async {
    await createExercises(3);
    await pumpExercises(tester);

    await longPressExercise(tester, "Exercise 1");
    await tester.tap(find.byIcon(Icons.select_all));
    await settle(tester);

    expect(find.text("3 selected"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.deselect));
    await settle(tester);

    expect(find.text("Exercises"), findsOneWidget);
  });
}
