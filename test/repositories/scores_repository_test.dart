/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository repo;

  final timestamp = DateTime.utc(2026, 1, 1);

  Future<void> insertScore(
    String id, {
    List<String> instruments = const [],
    List<String> genres = const [],
  }) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: " title $id ",
        fileDownloaded: false,
        fileType: FileType.pdf,
        lastOpened: Value(timestamp),
        metadataUpdatedAt: Value(timestamp),
        fileUpdatedAt: Value(timestamp),
      ),
    );
    for (final instrument in instruments) {
      await db.managers.instrumentsTable.create(
        (o) => o(score: id, instrument: instrument),
      );
    }
    for (final genre in genres) {
      await db.managers.genresTable.create((o) => o(score: id, genre: genre));
    }
  }

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
  });

  tearDown(() async {
    await db.close();
  });

  test(
    "pages hold a full page of scores regardless of their relations",
    () async {
      for (final id in ["a", "b", "c", "d", "e"]) {
        await insertScore(
          id,
          instruments: ["piano", "violin", "cello"],
          genres: ["classical", "baroque"],
        );
      }

      final first = await repo.getScores(size: 2);
      final second = await repo.getScores(size: 2, offset: 2);
      final third = await repo.getScores(size: 2, offset: 4);

      expect(first.map((s) => s.id), ["a", "b"]);
      expect(second.map((s) => s.id), ["c", "d"]);
      expect(third.map((s) => s.id), ["e"]);
    },
  );

  test("score ids cover every match without join duplicates", () async {
    for (final id in ["a", "b", "c"]) {
      await insertScore(
        id,
        instruments: ["piano", "violin"],
        genres: ["classical", "baroque"],
      );
    }
    await insertScore("d");

    final all = await repo.getScoreIds();
    final filtered = await repo.getScoreIds(instruments: ["piano", "violin"]);

    expect(all, ["a", "b", "c", "d"]);
    expect(filtered, ["a", "b", "c"]);
  });

  test("scores carry their sorted genres and instruments", () async {
    await insertScore(
      "a",
      instruments: ["violin", "cello", "piano"],
      genres: ["classical", "baroque"],
    );
    await insertScore("b");

    final scores = (await repo.getScores(size: 10)).toList();

    expect(scores[0].instruments, ["cello", "piano", "violin"]);
    expect(scores[0].genres, ["baroque", "classical"]);
    expect(scores[1].instruments, isEmpty);
    expect(scores[1].genres, isEmpty);
  });

  test("bulk editing the composer keeps the search text in sync", () async {
    await insertScore("a");
    await insertScore("b");

    await repo.bulkEditScoreComposer(["a", "b"], "Georg Friedrich Händel");

    expect((await repo.getScore("a"))!.composer, "Georg Friedrich Händel");
    final query = db.selectOnly(db.scoresTable)
      ..addColumns([db.scoresTable.searchText])
      ..where(db.scoresTable.id.equals("a"));
    final searchText = (await query.getSingle()).read(
      db.scoresTable.searchText,
    );
    expect(searchText, " title a georg friedrich handel ");

    await repo.bulkEditScoreComposer(["a"], "");

    expect((await repo.getScore("a"))!.composer, null);
    expect((await repo.getScore("b"))!.composer, "Georg Friedrich Händel");
  });

  test("bulk editing the source only touches the selected scores", () async {
    await insertScore("a");
    await insertScore("b");
    await insertScore("c");

    await repo.bulkEditScoreSource(["a", "b"], "IMSLP", "https://imslp.org");

    expect((await repo.getScore("a"))!.source, "IMSLP");
    expect((await repo.getScore("a"))!.sourceLink, "https://imslp.org");
    expect((await repo.getScore("b"))!.source, "IMSLP");
    expect((await repo.getScore("c"))!.source, null);
    expect((await repo.getScore("c"))!.sourceLink, null);

    await repo.bulkEditScoreSource(["a"], "", "");

    expect((await repo.getScore("a"))!.source, null);
    expect((await repo.getScore("a"))!.sourceLink, null);
    expect((await repo.getScore("b"))!.source, "IMSLP");
    expect((await repo.getScore("b"))!.sourceLink, "https://imslp.org");
  });

  test("an empty source name drops the link", () async {
    await insertScore("a");

    await repo.updateScoreSource(
      "a",
      source: "IMSLP",
      sourceLink: "https://imslp.org",
    );
    expect((await repo.getScore("a"))!.sourceLink, "https://imslp.org");

    await repo.updateScoreSource(
      "a",
      source: "",
      sourceLink: "https://imslp.org",
    );

    expect((await repo.getScore("a"))!.source, null);
    expect((await repo.getScore("a"))!.sourceLink, null);
  });

  test("bulk editing instruments only touches the selected scores", () async {
    await insertScore("a", instruments: ["piano", "violin"]);
    await insertScore("b", instruments: ["piano"]);
    await insertScore("c", instruments: ["violin"]);

    await repo.bulkEditScoreInstruments(["a", "b"], ["cello"], ["piano"]);

    expect((await repo.getScore("a"))!.instruments, ["cello", "violin"]);
    expect((await repo.getScore("b"))!.instruments, ["cello"]);
    expect((await repo.getScore("c"))!.instruments, ["violin"]);
  });

  test("bulk editing genres only touches the selected scores", () async {
    await insertScore("a", genres: ["classical", "baroque"]);
    await insertScore("b", genres: ["classical"]);
    await insertScore("c", genres: ["baroque"]);

    await repo.bulkEditScoreGenres(["a", "b"], ["jazz"], ["classical"]);

    expect((await repo.getScore("a"))!.genres, ["baroque", "jazz"]);
    expect((await repo.getScore("b"))!.genres, ["jazz"]);
    expect((await repo.getScore("c"))!.genres, ["baroque"]);
  });
}
