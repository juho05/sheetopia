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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/rounded_list_tile.dart';
import 'package:sheetopia/ui/common/selection/selection_model.dart';
import 'package:sheetopia/ui/setlists/bulk_edit/setlists_bulk_edit_menu.dart';
import 'package:sheetopia/ui/setlists/setlists_view.dart';
import 'package:sheetopia/ui/setlists/setlists_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository scoresRepo;
  late SetlistsRepository repo;
  late SetlistsViewModel viewModel;
  late SelectionModel selection;

  Future<void> createSetlists(int count) async {
    for (var i = 0; i < count; i++) {
      await repo.createSetlist(name: "Setlist $i");
    }
  }

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
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

  Future<void> pumpSetlists(WidgetTester tester) async {
    // the view model must be built inside the test zone so its queries
    // are not stuck behind the drift lock
    viewModel = SetlistsViewModel(repo: repo);
    addTearDown(viewModel.dispose);
    tester.view.physicalSize = const Size(800, 1200);
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
                    selecting ? "${selection.length} selected" : "Setlists",
                  ),
                  actions: selecting
                      ? [
                          SetlistsBulkEditMenu(
                            selectedSetlistIds: selection.ids,
                            onDeleted: selection.clear,
                          ),
                        ]
                      : null,
                ),
                body: SetlistsView(
                  viewModel: viewModel,
                  selectionMode: selecting,
                  selected: selection.idSet,
                  onSetlistSelected: (setlist) => selection.select(setlist.id),
                  onSetlistDeselected: (setlist) =>
                      selection.deselect(setlist.id),
                  onSetlistsSelected: selection.selectAll,
                  onClearSelection: selection.clear,
                ),
              );
            },
          ),
        ),
        GoRoute(
          path: "/setlists/:id",
          builder: (context, state) => const Text("setlist page"),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SetlistsRepository>.value(value: repo),
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

  Future<void> tapSetlist(
    WidgetTester tester,
    String name, {
    LogicalKeyboardKey? modifier,
  }) async {
    if (modifier != null) await tester.sendKeyDownEvent(modifier);
    await tester.tap(tileOf(name));
    if (modifier != null) await tester.sendKeyUpEvent(modifier);
    await settle(tester);
  }

  Future<void> longPressSetlist(WidgetTester tester, String name) async {
    await tester.longPress(tileOf(name));
    await settle(tester);
  }

  testWidgets("a long press starts the selection", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await longPressSetlist(tester, "Setlist 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("Setlists"), findsNothing);
  });

  testWidgets("the selection icon replaces the setlist icon", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    expect(find.byIcon(Icons.queue_music), findsNWidgets(3));

    await longPressSetlist(tester, "Setlist 1");

    expect(find.byIcon(Icons.queue_music), findsNothing);
    expect(find.byIcon(Symbols.check), findsOneWidget);
    expect(find.byIcon(Symbols.radio_button_unchecked), findsNWidgets(2));
  });

  testWidgets("ctrl+click starts the selection instead of opening", (
    tester,
  ) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await tapSetlist(tester, "Setlist 1", modifier: LogicalKeyboardKey.control);

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("setlist page"), findsNothing);
  });

  testWidgets("a tap opens the setlist while not selecting", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await tapSetlist(tester, "Setlist 1");

    expect(find.text("setlist page"), findsOneWidget);
  });

  testWidgets("a tap toggles the setlist while selecting", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await longPressSetlist(tester, "Setlist 0");
    await tapSetlist(tester, "Setlist 1");

    expect(find.text("2 selected"), findsOneWidget);

    await tapSetlist(tester, "Setlist 1");

    expect(find.text("1 selected"), findsOneWidget);
    expect(find.text("setlist page"), findsNothing);
  });

  testWidgets("shift+click selects the range after the anchor", (tester) async {
    await createSetlists(5);
    await pumpSetlists(tester);

    await tapSetlist(tester, "Setlist 1", modifier: LogicalKeyboardKey.control);
    await tapSetlist(
      tester,
      "Setlist 3",
      modifier: LogicalKeyboardKey.shiftLeft,
    );

    expect(find.text("3 selected"), findsOneWidget);
    expect(find.byIcon(Symbols.check), findsNWidgets(3));
  });

  testWidgets("ctrl+a selects every setlist", (tester) async {
    await createSetlists(5);
    await pumpSetlists(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await settle(tester);

    expect(find.text("5 selected"), findsOneWidget);
  });

  testWidgets("escape clears the selection", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await longPressSetlist(tester, "Setlist 1");
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    expect(find.text("Setlists"), findsOneWidget);
  });

  testWidgets("the bulk menu deletes the selected setlists", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await longPressSetlist(tester, "Setlist 0");
    await tapSetlist(tester, "Setlist 1");

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text("Delete"));
    await settle(tester);

    expect(find.text("Delete 2 setlists?"), findsOneWidget);

    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(await repo.countSetlists(), 1);
    expect(find.text("Setlist 2"), findsOneWidget);
    expect(find.text("Setlists"), findsOneWidget);
  });

  testWidgets("cancelling the confirmation keeps the setlists", (tester) async {
    await createSetlists(3);
    await pumpSetlists(tester);

    await longPressSetlist(tester, "Setlist 0");

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text("Delete"));
    await settle(tester);
    await tester.tap(find.text("Cancel"));
    await settle(tester);

    expect(await repo.countSetlists(), 3);
    expect(find.text("1 selected"), findsOneWidget);
  });
}
