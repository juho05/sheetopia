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

  Future<void> insertScore(String id, {bool downloaded = true}) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        composer: Value("Composer $id"),
        searchText: "title $id",
        fileDownloaded: downloaded,
        fileType: FileType.pdf,
      ),
    );
  }

  Future<List<int>> positionsOf(String setlistId) async {
    final query = db.select(db.setlistEntriesTable)
      ..where((t) => t.setlist.equals(setlistId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);
    return (await query.get()).map((e) => e.position).toList();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("setlists_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    repo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test("an empty setlist is listed with a count of 0", () async {
    await repo.createSetlist(name: "Empty");
    final setlists = await repo.getSetlists();
    expect(setlists, hasLength(1));
    expect(setlists.single.name, "Empty");
    expect(setlists.single.entryCount, 0);
    expect(setlists.single.entries, isEmpty);
  });

  test("setlists are ordered by name, then id", () async {
    final first = await repo.createSetlist(name: "Set");
    final second = await repo.createSetlist(name: "Set");
    await repo.createSetlist(name: "Another");

    final setlists = await repo.getSetlists();
    expect(setlists.map((s) => s.name), ["Another", "Set", "Set"]);
    expect(
      setlists.skip(1).map((s) => s.id).toList(),
      [first.id, second.id]..sort(),
    );
  });

  test("entryCount counts rows that do not resolve locally", () async {
    final setlist = await repo.createSetlist(name: "Set");
    await insertScore("a");
    await repo.addScores(setlist.id, ["a", "missing", "a"]);
    expect((await repo.getSetlists()).single.entryCount, 3);
  });

  test("getSetlist keeps unresolved entries at their position", () async {
    final setlist = await repo.createSetlist(name: "Set");
    await insertScore("a");
    await insertScore("c", downloaded: false);
    await repo.addScores(setlist.id, ["a", "missing", "c"]);

    final full = (await repo.getSetlist(setlist.id))!;
    expect(full.entries.map((e) => e.scoreId), ["a", "missing", "c"]);
    expect(full.entryCount, 3);

    expect(full.entries[0].score, isNotNull);
    expect(full.entries[0].playable, isTrue);

    expect(full.entries[1].score, isNull);
    expect(full.entries[1].playable, isFalse);

    expect(full.entries[2].score, isNotNull);
    expect(full.entries[2].score!.file, isNull);
    expect(full.entries[2].playable, isFalse);
  });

  test("duplicate scores are kept as separate entries", () async {
    final setlist = await repo.createSetlist(name: "Set");
    await insertScore("a");
    await repo.addScores(setlist.id, ["a", "a", "a"]);
    expect((await repo.getSetlist(setlist.id))!.entries, hasLength(3));
  });

  test("addScores appends after a gap without renumbering", () async {
    final setlist = await repo.createSetlist(name: "Set");
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    await repo.addScores(setlist.id, ["a", "b", "c"]);
    await repo.removeDeletedScoreEntries({"b"});
    expect(await positionsOf(setlist.id), [0, 2]);

    await repo.addScores(setlist.id, ["b"]);
    expect(await positionsOf(setlist.id), [0, 2, 3]);
    expect((await repo.getSetlist(setlist.id))!.entries.map((e) => e.scoreId), [
      "a",
      "c",
      "b",
    ]);
  });

  test("moveEntry and removeEntry address gapped lists by index", () async {
    final setlist = await repo.createSetlist(name: "Set");
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");
    await insertScore("d");
    await repo.addScores(setlist.id, ["a", "b", "c", "d"]);
    await repo.removeDeletedScoreEntries({"b"});
    expect(await positionsOf(setlist.id), [0, 2, 3]);

    await repo.moveEntry(setlist.id, 2, 0);
    expect((await repo.getSetlist(setlist.id))!.entries.map((e) => e.scoreId), [
      "d",
      "a",
      "c",
    ]);
    expect(await positionsOf(setlist.id), [0, 1, 2]);

    await repo.removeEntry(setlist.id, 1);
    expect((await repo.getSetlist(setlist.id))!.entries.map((e) => e.scoreId), [
      "d",
      "c",
    ]);
  });

  test(
    "deleting a score removes its entries and marks setlists dirty",
    () async {
      final setlist = await repo.createSetlist(name: "Set");
      await insertScore("a");
      await insertScore("b");
      await repo.addScores(setlist.id, ["a", "b", "a"]);
      await db.managers.setlistsTable.update(
        (o) => o(uploaded: const Value(true)),
      );

      final events = <Set<String>>[];
      final sub = repo.locallyUpdatedSetlistIds.listen(events.add);
      await scoresRepo.deleteScore("a");
      await pumpEventQueue();
      await sub.cancel();
      expect(events.last, {setlist.id});

      final full = (await repo.getSetlist(setlist.id))!;
      expect(full.entries.map((e) => e.scoreId), ["b"]);
      expect(
        (await db.managers.setlistsTable.getSingle()).uploaded,
        isFalse,
        reason: "the corrected entry list must be re-uploaded",
      );
    },
  );

  test(
    "deleteSetlist writes a tombstone, deleteAllSetlists does not",
    () async {
      final setlist = await repo.createSetlist(name: "Set");
      await insertScore("a");
      await repo.addScores(setlist.id, ["a"]);

      await repo.deleteSetlist(setlist.id);
      expect(await db.managers.deletedSetlistsTable.count(), 1);
      expect(await db.managers.setlistEntriesTable.count(), 0);

      final other = await repo.createSetlist(name: "Other");
      await repo.addScores(other.id, ["a"]);
      await repo.deleteAllSetlists();
      expect(await db.managers.setlistsTable.count(), 0);
      expect(await db.managers.setlistEntriesTable.count(), 0);
      expect(await db.managers.deletedSetlistsTable.count(), 0);
    },
  );

  test("deleteAllSetlists announces the wiped ids", () async {
    final setlist = await repo.createSetlist(name: "Set");
    final events = <Set<String>>[];
    final sub = repo.updatedSetlistIds.listen(events.add);
    await repo.deleteAllSetlists();
    await pumpEventQueue();
    await sub.cancel();
    expect(events.last, {setlist.id});
  });

  test("getSetlist returns null for an unknown id", () async {
    expect(await repo.getSetlist("nope"), isNull);
  });

  test("deleteSetlists removes them all and their entries", () async {
    await insertScore("s1");
    final first = await repo.createSetlist(name: "First");
    final second = await repo.createSetlist(name: "Second");
    final kept = await repo.createSetlist(name: "Kept");
    await repo.addScores(first.id, ["s1"]);

    await repo.deleteSetlists({first.id, second.id});

    expect((await repo.getSetlists()).map((s) => s.name), ["Kept"]);
    expect(await repo.getSetlist(kept.id), isNotNull);
    expect(await db.managers.setlistEntriesTable.count(), 0);
  });

  test("deleteSetlists records a tombstone per setlist", () async {
    final first = await repo.createSetlist(name: "First");
    final second = await repo.createSetlist(name: "Second");

    await repo.deleteSetlists({first.id, second.id});

    final deleted = await db.managers.deletedSetlistsTable.get();
    expect(deleted.map((d) => d.setlistId).toSet(), {first.id, second.id});
  });

  test("deleteSetlists announces every deleted id at once", () async {
    final first = await repo.createSetlist(name: "First");
    final second = await repo.createSetlist(name: "Second");
    final events = <Set<String>>[];
    final sub = repo.updatedSetlistIds.listen(events.add);

    await repo.deleteSetlists({first.id, second.id});
    await pumpEventQueue();
    await sub.cancel();

    expect(events.last, {first.id, second.id});
  });

  test("deleting an empty selection does nothing", () async {
    await repo.createSetlist(name: "First");

    await repo.deleteSetlists({});

    expect(await repo.countSetlists(), 1);
    expect(await db.managers.deletedSetlistsTable.count(), 0);
  });
}
