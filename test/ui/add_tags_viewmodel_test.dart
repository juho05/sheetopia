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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/edit_score/add_tags_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/edit_tag_viewmodel.dart';

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

  Future<AddTagsViewModel> pumpViewModel(
    TagType type, {
    Set<Tag> selected = const {},
  }) async {
    final viewModel = AddTagsViewModel(
      scoreTags: selected,
      repo: repo,
      type: type,
    );
    addTearDown(viewModel.dispose);
    await Future.delayed(Duration.zero);
    return viewModel;
  }

  test("only tags of the dialog's type are offered", () async {
    await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    await repo.createTag(
      name: "Warmup",
      color: Colors.blue,
      type: TagType.exercise,
    );

    final scores = await pumpViewModel(TagType.score);
    final exercises = await pumpViewModel(TagType.exercise);

    expect(scores.results.map((t) => t.name), ["Recital"]);
    expect(exercises.results.map((t) => t.name), ["Warmup"]);
  });

  test("managing tags stays within the type", () async {
    await repo.createTag(
      name: "Recital",
      color: Colors.red,
      type: TagType.score,
    );
    final warmup = await repo.createTag(
      name: "Warmup",
      color: Colors.blue,
      type: TagType.exercise,
    );

    final viewModel = await pumpViewModel(TagType.exercise, selected: {warmup});
    expect(viewModel.results, isEmpty);

    await viewModel.enterManageTagsMode();

    expect(viewModel.results.map((t) => t.name), ["Warmup"]);
  });

  test("the create dialog stores the type it was opened with", () async {
    final viewModel = EditTagViewModel(repo: repo, type: TagType.exercise);
    viewModel.form.control(EditTagViewModel.formName).value = "Warmup";

    final tag = await viewModel.createTag();

    expect((await repo.getTags(type: TagType.exercise)).map((t) => t.id), [
      tag.id,
    ]);
    expect(await repo.getTags(type: TagType.score), isEmpty);
  });
}
