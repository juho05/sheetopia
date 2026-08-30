/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/setlists/setlist_navigation_viewmodel.dart';

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

  late Directory tempDir;
  late Database db;
  late ScoresRepository scoresRepo;
  late SetlistsRepository repo;
  late String setlistId;

  Future<void> insertScore(String id, {bool downloaded = true}) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileDownloaded: downloaded,
        fileType: FileType.pdf,
      ),
    );
  }

  Future<void> markDownloaded(String id) async {
    await db.managers.scoresTable
        .filter((f) => f.id(id))
        .update((o) => o(fileDownloaded: const Value(true)));
    scoresRepo.remoteChangedScores({id});
  }

  Future<SetlistNavigationViewModel> navigationFor() async {
    final setlist = (await repo.getSetlist(setlistId))!;
    return SetlistNavigationViewModel(
      setlist,
      repo: repo,
      scoresRepo: scoresRepo,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("setlist_nav_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
    setlistId = (await repo.createSetlist(name: "Set")).id;
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test("play starts at the first playable entry, not index 0", () async {
    await insertScore("a", downloaded: false);
    await insertScore("b");
    await repo.addScores(setlistId, ["a", "b"]);

    final nav = await navigationFor();
    expect(nav.position, 1);
    expect(nav.currentScoreId, "b");
    nav.dispose();
  });

  test("advance and goBack skip unplayable entries", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    await insertScore("c");
    await repo.addScores(setlistId, ["a", "b", "c", "missing"]);

    final nav = await navigationFor();
    expect(nav.position, 0);

    expect(nav.next(), isTrue);
    expect(nav.position, 2, reason: "b has no file, missing has no row");
    expect(nav.next(), isFalse, reason: "must not wrap");
    expect(nav.position, 2);

    expect(nav.previous(), isTrue);
    expect(nav.position, 0);
    expect(nav.previous(), isFalse);
    nav.dispose();
  });

  test("advance into a reprise moves the index", () async {
    await insertScore("a");
    await repo.addScores(setlistId, ["a", "a"]);

    final nav = await navigationFor();
    expect(nav.position, 0);
    expect(nav.next(), isTrue);
    expect(nav.position, 1);
    expect(nav.currentScoreId, "a");
    nav.dispose();
  });

  test("jumpTo an unplayable entry is a no-op", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    await repo.addScores(setlistId, ["a", "b"]);

    final nav = await navigationFor();
    nav.jumpTo(1);
    expect(nav.position, 0);
    nav.jumpTo(5);
    expect(nav.position, 0);
    nav.dispose();
  });

  test("index is -1 when nothing is playable, and recovers", () async {
    await insertScore("a", downloaded: false);
    await insertScore("b", downloaded: false);
    await repo.addScores(setlistId, ["a", "b"]);

    final nav = await navigationFor();
    expect(nav.position, -1);
    expect(nav.currentScoreId, isNull);

    await markDownloaded("b");
    await pumpEventQueue();

    expect(nav.position, 1, reason: "recovers without a second subscription");
    expect(nav.currentScoreId, "b");
    nav.dispose();
  });

  test("a resolution-only reload must not move the score on screen", () async {
    await insertScore("a");
    await insertScore("b", downloaded: false);
    await insertScore("c");
    await repo.addScores(setlistId, ["a", "b", "c"]);

    final nav = await navigationFor();
    nav.jumpTo(2);
    expect(nav.position, 2);

    await markDownloaded("b");
    await pumpEventQueue();

    expect(nav.position, 2, reason: "a background sync must not turn the page");
    expect(nav.currentScoreId, "c");
    expect(nav.entries[1].playable, isTrue, reason: "but it does resolve");
    nav.dispose();
  });

  test("a structural reload re-anchors on the current score", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    await repo.addScores(setlistId, ["a", "b", "c"]);

    final nav = await navigationFor();
    nav.jumpTo(2);
    expect(nav.currentScoreId, "c");

    // a peer reorders the setlist while it is being played
    await repo.moveEntry(setlistId, 2, 0);
    await pumpEventQueue();

    expect(nav.position, 0, reason: "followed the score, not the index");
    expect(nav.currentScoreId, "c");
    nav.dispose();
  });

  test("re-anchoring falls back to a nearby entry", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    await repo.addScores(setlistId, ["a", "b", "c"]);

    final nav = await navigationFor();
    nav.jumpTo(1);
    expect(nav.currentScoreId, "b");

    await scoresRepo.deleteScore("b");
    await pumpEventQueue();

    expect(nav.length, 2);
    expect(nav.currentScoreId, "c");
    nav.dispose();
  });

  test("a deleted setlist is reported, not played on", () async {
    await insertScore("a");
    await repo.addScores(setlistId, ["a"]);

    final nav = await navigationFor();
    expect(nav.deleted, isFalse);

    await repo.deleteSetlist(setlistId);
    await pumpEventQueue();

    expect(nav.deleted, isTrue);
    expect(nav.name, "Set", reason: "must not null out the setlist");
    nav.dispose();
  });
}
