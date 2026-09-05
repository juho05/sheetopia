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
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/practice/bulk_edit/routines_bulk_edit_menu.dart';
import 'package:sheetopia/ui/practice/practice_page.dart';
import 'package:sheetopia/ui/practice/practice_routines_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;
  late ScoresRepository scoresRepo;
  late PracticeRoutinesViewModel viewModel;
  late SelectionModel selection;

  Future<String> createRoutine(String name) async {
    final id = db.newId();
    await db.managers.practiceRoutinesTable.create(
      (o) => o(id: id, name: name),
    );
    return id;
  }

  Future<void> createRoutines(int count) async {
    for (var i = 0; i < count; i++) {
      await createRoutine("Routine $i");
    }
  }

  Future<List<String>> routineNames() async =>
      (await repo.getRoutines(size: 100)).map((r) => r.name).toList();

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    selection = SelectionModel();
  });

  tearDown(() async {
    selection.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpRoutines(WidgetTester tester) async {
    // the view model must be built inside the test zone so its queries
    // are not stuck behind the drift lock
    viewModel = PracticeRoutinesViewModel(repo: repo, scoresRepo: scoresRepo);
    addTearDown(viewModel.dispose);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => ListenableBuilder(
            listenable: selection,
            builder: (context, _) {
              final selecting = selection.isNotEmpty;
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    selecting ? "${selection.length} selected" : "Practice",
                  ),
                  actions: selecting
                      ? [
                          RoutinesBulkEditMenu(
                            selectedRoutineIds: selection.ids,
                            onDeleted: selection.clear,
                          ),
                        ]
                      : null,
                ),
                body: PracticePage(
                  viewModel: viewModel,
                  selectionMode: selecting,
                  selected: selection.idSet,
                  onRoutineSelected: (routine) => selection.select(routine.id),
                  onRoutineDeselected: (routine) =>
                      selection.deselect(routine.id),
                  onRoutinesSelected: selection.selectAll,
                  onClearSelection: selection.clear,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: "/practice/routines/:routineId/details",
          builder: (context, state) => const Text("routine details"),
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

  Future<void> tapRoutine(
    WidgetTester tester,
    String name, {
    LogicalKeyboardKey? modifier,
  }) async {
    if (modifier != null) await tester.sendKeyDownEvent(modifier);
    await tester.tap(tileOf(name));
    if (modifier != null) await tester.sendKeyUpEvent(modifier);
    await settle(tester);
  }

  Future<void> longPressRoutine(WidgetTester tester, String name) async {
    await tester.longPress(tileOf(name));
    await settle(tester);
  }

  Future<void> openBulkMenu(WidgetTester tester, String option) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text(option));
    await settle(tester);
  }

  testWidgets("a long press starts the selection", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("Practice"), findsNothing);
  });

  testWidgets("the selection icon replaces the routine icon", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    expect(find.byIcon(Symbols.checklist), findsNWidgets(3));

    await longPressRoutine(tester, "Routine 1");

    expect(find.byIcon(Symbols.checklist), findsNothing);
    expect(find.byIcon(Symbols.check), findsOneWidget);
    expect(find.byIcon(Symbols.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets("ctrl+click starts the selection instead of opening", (
    tester,
  ) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await tapRoutine(tester, "Routine 1", modifier: LogicalKeyboardKey.control);

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("routine details"), findsNothing);
  });

  testWidgets("a tap opens the routine while not selecting", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await tapRoutine(tester, "Routine 1");

    expect(find.text("routine details"), findsOneWidget);
  });

  testWidgets("a tap toggles the routine while selecting", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 0");
    await tapRoutine(tester, "Routine 1");

    expect(find.text("2 selected"), findsOneWidget);

    await tapRoutine(tester, "Routine 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("routine details"), findsNothing);
  });

  testWidgets("shift+click selects the range after the anchor", (tester) async {
    await createRoutines(5);
    await pumpRoutines(tester);

    await tapRoutine(tester, "Routine 1", modifier: LogicalKeyboardKey.control);
    await tapRoutine(
      tester,
      "Routine 3",
      modifier: LogicalKeyboardKey.shiftLeft,
    );

    expect(find.text("3 selected"), findsOneWidget);
  });

  testWidgets("ctrl+a selects every routine", (tester) async {
    await createRoutines(5);
    await pumpRoutines(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await settle(tester);

    expect(find.text("5 selected"), findsOneWidget);
  });

  testWidgets("escape clears the selection", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 1");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    expect(find.text("Practice"), findsOneWidget);
  });

  testWidgets("the bulk menu deletes the selected routines", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 0");
    await tapRoutine(tester, "Routine 1");

    await openBulkMenu(tester, "Delete");

    expect(find.text("Delete 2 routines?"), findsOneWidget);

    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(await routineNames(), ["Routine 2"]);
    expect(find.text("Practice"), findsOneWidget);
  });

  testWidgets("the bulk menu duplicates the selected routines", (tester) async {
    await createRoutines(2);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 0");
    await tapRoutine(tester, "Routine 1");

    await openBulkMenu(tester, "Duplicate");

    expect(await routineNames(), [
      "Routine 0",
      "Routine 0 (copy)",
      "Routine 1",
      "Routine 1 (copy)",
    ]);
  });

  testWidgets("cancelling the confirmation keeps the routines", (tester) async {
    await createRoutines(3);
    await pumpRoutines(tester);

    await longPressRoutine(tester, "Routine 0");

    await openBulkMenu(tester, "Delete");
    await tester.tap(find.text("Cancel"));
    await settle(tester);

    expect(await repo.countRoutines(), 3);
    expect(find.text("1 selected"), findsOneWidget);
  });
}
