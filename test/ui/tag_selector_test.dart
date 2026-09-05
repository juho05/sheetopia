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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/common/tag_selector.dart';

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

  late List<Tag> selected;

  Future<void> pumpSelector(WidgetTester tester, List<Tag> tags) async {
    selected = tags;
    await tester.pumpWidget(
      Provider<ScoresRepository>.value(
        value: repo,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagSelector(
                tags: selected,
                type: TagType.score,
                onAdd: (tags) =>
                    setState(() => selected = [...selected, ...tags]),
                onRemove: (tag) =>
                    setState(() => selected = [...selected]..remove(tag)),
                onSynced: (tags) => setState(() => selected = tags),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("an edited tag is shown with its new name", (tester) async {
    final tag = await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    await pumpSelector(tester, [tag]);

    expect(find.text("Recital"), findsOneWidget);

    await repo.updateTag(tag.id, name: "Concert", color: Colors.blue);
    await tester.pumpAndSettle();

    expect(find.text("Recital"), findsNothing);
    expect(find.text("Concert"), findsOneWidget);
    expect(selected.single.name, "Concert");
  });

  testWidgets("a deleted tag is removed from the selection", (tester) async {
    final recital = await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    final warmup = await repo.createTag(
      name: "Warmup",
      color: Colors.blue,
      type: TagType.score,
    );
    await pumpSelector(tester, [recital, warmup]);

    await repo.deleteTag(recital.id);
    await tester.pumpAndSettle();

    expect(find.text("Recital"), findsNothing);
    expect(find.text("Warmup"), findsOneWidget);
    expect(selected.single.id, warmup.id);
  });

  testWidgets("tags deleted while the selector is gone are dropped on the "
      "next build", (tester) async {
    final tag = await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    await repo.deleteTag(tag.id);

    await pumpSelector(tester, [tag]);

    expect(find.text("Recital"), findsNothing);
    expect(selected, isEmpty);
  });

  testWidgets("changes to other tags keep the selection", (tester) async {
    final recital = await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    final warmup = await repo.createTag(
      name: "Warmup",
      color: Colors.blue,
      type: TagType.score,
    );
    await pumpSelector(tester, [recital]);
    final before = selected;

    await repo.updateTag(warmup.id, name: "Cooldown", color: Colors.green);
    await tester.pumpAndSettle();

    expect(find.text("Recital"), findsOneWidget);
    expect(selected, same(before));
  });
}
