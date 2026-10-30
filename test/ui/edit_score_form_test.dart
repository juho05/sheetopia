/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Database db;
  late ScoresRepository repo;

  setUp(() async {
    db = Database(NativeDatabase.memory());
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    await db.managers.scoresTable.create(
      (o) => o(
        id: "a",
        title: "Title",
        searchText: " title ",
        fileType: FileType.pdf,
        fileDownloaded: false,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: repo),
          ChangeNotifierProvider(
            create: (context) =>
                EditScoreViewModel(repo: repo, scoreId: "a", isImport: false),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<EditScoreViewModel>(
              builder: (context, viewModel, _) => viewModel.score == null
                  ? const SizedBox()
                  : const EditScoreForm(),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets("empty optional fields are hidden until added", (tester) async {
    await pumpForm(tester);

    expect(find.text("Composer"), findsOneWidget);
    expect(find.text("Instruments"), findsOneWidget);
    expect(find.text("Tags"), findsOneWidget);
    expect(find.text("Arranger"), findsNothing);
    expect(find.byType(DifficultySelector), findsNothing);
    expect(find.text("Genres"), findsNothing);

    await tester.tap(find.text("Add field"));
    await settle(tester);
    await tester.tap(find.text("Difficulty"));
    await settle(tester);

    expect(find.byType(DifficultySelector), findsOneWidget);
    expect(find.text("Difficulty"), findsOneWidget);
    expect(find.byTooltip("No difficulty"), findsNothing);
  });

  testWidgets("an added empty field stays until it is removed", (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text("Add field"));
    await settle(tester);
    await tester.tap(find.text("Arranger"));
    await settle(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester);

    expect(find.text("Arranger"), findsOneWidget);

    await tester.tap(find.byTooltip("Remove field"));
    await settle(tester);

    expect(find.text("Arranger"), findsNothing);
  });

  testWidgets("tapping the selected difficulty clears it", (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text("Add field"));
    await settle(tester);
    await tester.tap(find.text("Difficulty"));
    await settle(tester);
    await tester.tap(find.byTooltip("Hard"));
    await settle(tester);

    expect((await repo.getScore("a"))!.difficulty, Difficulty.hard);

    await tester.tap(find.byTooltip("Hard"));
    await settle(tester);

    expect((await repo.getScore("a"))!.difficulty, isNull);
  });

  testWidgets("filled optional fields are shown and can be removed", (
    tester,
  ) async {
    await repo.updateScoreDifficulty("a", Difficulty.easy);
    await pumpForm(tester);

    expect(find.byType(DifficultySelector), findsOneWidget);
    await tester.tap(find.byTooltip("Remove field"));
    await settle(tester);
    await tester.tap(find.text("Yes"));
    await settle(tester);

    expect(find.byType(DifficultySelector), findsNothing);
    expect((await repo.getScore("a"))!.difficulty, isNull);
  });

  testWidgets("the source is edited in place", (tester) async {
    await repo.updateScoreSource("a", source: "IMSLP", sourceLink: "");
    await pumpForm(tester);

    await tester.enterText(find.widgetWithText(TextField, "IMSLP"), "Henle");
    await settle(tester);

    expect((await repo.getScore("a"))!.source, "Henle");
  });

  TextSelection selectionOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.selection;

  const fullTitle = TextSelection(baseOffset: 0, extentOffset: 5);

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets(
      "tapping a metadata field selects its value with ${kind.name}",
      (tester) async {
        await pumpForm(tester);
        final title = find.widgetWithText(TextField, "Title");

        await tester.tap(title, kind: kind);
        await settle(tester);
        expect(selectionOf(tester, title), fullTitle);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.linux,
        TargetPlatform.android,
      }),
    );

    testWidgets(
      "tapping a focused metadata field places the caret with ${kind.name}",
      (tester) async {
        await pumpForm(tester);
        final title = find.widgetWithText(TextField, "Title");

        await tester.tap(title, kind: kind);
        await settle(tester);
        await tester.pump(kDoubleTapTimeout);
        await tester.tap(title, kind: kind);
        await settle(tester);
        expect(selectionOf(tester, title).isCollapsed, isTrue);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.linux,
        TargetPlatform.android,
      }),
    );
  }

  testWidgets("tapping a metadata field selects a composer again after blur", (
    tester,
  ) async {
    await db.managers.scoresTable
        .filter((f) => f.id("a"))
        .update((o) => o(composer: const Value("Bach")));
    await pumpForm(tester);
    final composer = find.widgetWithText(TextField, "Bach");

    await tester.tap(composer, kind: PointerDeviceKind.mouse);
    await settle(tester);
    await tester.tapAt(Offset.zero, kind: PointerDeviceKind.mouse);
    await settle(tester);
    await tester.pump(kDoubleTapTimeout);
    await tester.tap(composer, kind: PointerDeviceKind.mouse);
    await settle(tester);

    expect(
      selectionOf(tester, composer),
      const TextSelection(baseOffset: 0, extentOffset: 4),
    );
  });

  testWidgets("dragging over a metadata field keeps the dragged selection", (
    tester,
  ) async {
    await pumpForm(tester);
    final title = find.widgetWithText(TextField, "Title");
    final start = tester.getTopLeft(title) + const Offset(40, 20);

    final gesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.up();
    await settle(tester);

    final selection = selectionOf(tester, title);
    expect(selection.isCollapsed, isFalse);
    expect(selection, isNot(fullTitle));
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
