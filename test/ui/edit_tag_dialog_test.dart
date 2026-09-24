/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' show ColorPicker;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/edit_score/edit_tag_dialog.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository repo;

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets("a tag is created with a color from the picker", (tester) async {
    Tag? created;
    await tester.pumpWidget(
      Provider<ScoresRepository>.value(
        value: repo,
        child: MaterialApp(
          builder: (context, child) =>
              // ignore: deprecated_member_use
              MaterialUiCompatibilityBridge(child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => created = await EditTagDialog.showCreate(
                  context,
                  type: TagType.score,
                ),
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Recital");
    await tester.tap(find.text("Color"));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPicker), findsOneWidget);

    await tester.tap(find.text("RGB"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("HSV").last);
    await tester.pumpAndSettle();
    expect(find.text("HSV"), findsOneWidget);

    await tester.tap(find.text("Select"));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPicker), findsNothing);

    await tester.tap(find.text("Create"));
    await tester.pumpAndSettle();

    expect(created?.name, "Recital");
    expect(created?.color.toARGB32(), Colors.indigo.toARGB32());
    expect(tester.takeException(), isNull);
  });
}
