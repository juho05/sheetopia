/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/scores/score_processing_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/score_processing/background_color.dart';
import 'package:sheetopia/data/services/score_processing/score_processing_service.dart';
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

class _FakeProcessingService implements ScoreProcessingService {
  final List<String> processed = [];
  final Map<String, Completer<void>> blocked = {};
  final Set<String> failing = {};

  @override
  Future<ScoreProcessingResult> processPdf(String path) async {
    final id = path.split(Platform.pathSeparator).reversed.elementAt(1);
    processed.add(id);
    await blocked[id]?.future;
    if (failing.contains(id)) throw Exception("broken pdf");
    return ScoreProcessingResult(
      pageCount: 1,
      backgroundColor: 0xFF000000 | id.hashCode,
    );
  }

  @override
  void stop() {}
}

PageBitmap _page(
  int width,
  int height,
  (int, int, int) Function(int x, int y) color,
) {
  final bgra = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final (r, g, b) = color(x, y);
      final i = (y * width + x) * 4;
      bgra[i] = b;
      bgra[i + 1] = g;
      bgra[i + 2] = r;
      bgra[i + 3] = 255;
    }
  }
  return PageBitmap(width: width, height: height, bgra: bgra);
}

(int, int, int) _rgb(int argb) =>
    ((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);

void _expectColorNear(
  int? argb,
  (int, int, int) expected, {
  int tolerance = 6,
}) {
  expect(argb, isNotNull);
  final (r, g, b) = _rgb(argb!);
  expect((r - expected.$1).abs(), lessThanOrEqualTo(tolerance), reason: "r");
  expect((g - expected.$2).abs(), lessThanOrEqualTo(tolerance), reason: "g");
  expect((b - expected.$3).abs(), lessThanOrEqualTo(tolerance), reason: "b");
}

bool _isStaffLine(int y) => y % 20 < 2;

int? detectBackgroundColor(List<PageBitmap> pages) => combinePageBackgrounds([
  for (final page in pages) ?estimatePageBackground(page),
]);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();
  Log.init(LogRepository());
  Log.level = Level.off;

  group("background color detection", () {
    test("finds white behind dense notation", () {
      final page = _page(200, 280, (x, y) {
        if (_isStaffLine(y) || (x % 13 < 3 && y % 20 < 12)) return (0, 0, 0);
        return (255, 255, 255);
      });

      _expectColorNear(detectBackgroundColor([page]), (255, 255, 255));
    });

    test("ignores a dark surface around an imperfect crop", () {
      const paper = (232, 222, 196);
      final page = _page(200, 280, (x, y) {
        if (x < 30 || x > 185 || y < 10 || y > 250) return (40, 35, 30);
        if (_isStaffLine(y)) return (20, 20, 20);
        return paper;
      });

      _expectColorNear(detectBackgroundColor([page]), paper);
    });

    test("averages uneven lighting of camera scans", () {
      final page = _page(200, 280, (x, y) {
        if (_isStaffLine(y)) return (30, 30, 30);
        final shade = 200 + (x * 30 ~/ 200);
        return (shade, shade - 5, shade - 20);
      });

      _expectColorNear(detectBackgroundColor([page]), (
        215,
        210,
        195,
      ), tolerance: 10);
    });

    test("prefers lit paper over a smaller flat surface", () {
      final page = _page(200, 280, (x, y) {
        if (x < 25 || y > 235) return (70, 55, 40);
        if (_isStaffLine(y)) return (30, 30, 30);
        final shade = 205 + ((x - 25) * 35 ~/ 175);
        return (shade, shade - 6, shade - 24);
      });

      _expectColorNear(detectBackgroundColor([page]), (
        222,
        216,
        198,
      ), tolerance: 10);
    });

    test("outvotes a dark cover page", () {
      const paper = (250, 248, 240);
      final cover = _page(200, 280, (x, y) => (20, 30, 90));
      final pages = [
        cover,
        for (var i = 0; i < 3; i++)
          _page(200, 280, (x, y) => _isStaffLine(y) ? (0, 0, 0) : paper),
      ];

      _expectColorNear(detectBackgroundColor(pages), paper);
    });

    test("returns null without pages", () {
      expect(detectBackgroundColor([]), isNull);
    });
  });

  group("processing queue", () {
    late Directory tempDir;
    late Database db;
    late ScoresRepository scoresRepo;
    late _FakeProcessingService service;
    ScoreProcessingRepository? processing;

    final timestamp = DateTime.utc(2026, 1, 1);

    Future<void> insertScore(
      String id, {
      FileType fileType = FileType.pdf,
      bool fileDownloaded = true,
      int? processingVersion,
      DateTime? lastOpened,
    }) async {
      await db.managers.scoresTable.create(
        (o) => o(
          id: id,
          title: "Title $id",
          searchText: " title $id ",
          fileDownloaded: fileDownloaded,
          fileType: fileType,
          lastOpened: Value(lastOpened ?? timestamp),
          metadataUpdatedAt: Value(timestamp),
          fileUpdatedAt: Value(timestamp),
          processingVersion: Value(processingVersion),
        ),
      );
    }

    Future<ScoresTableData> row(String id) =>
        db.managers.scoresTable.filter((f) => f.id(id)).getSingle();

    ScoreProcessingRepository start() => processing = ScoreProcessingRepository(
      db: db,
      scoresRepo: scoresRepo,
      service: service,
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp("processing_test");
      PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
      db = Database(NativeDatabase.memory());
      scoresRepo = ScoresRepository(
        db: db,
        thumbnailService: ThumbnailService(),
      );
      service = _FakeProcessingService();
      processing = null;
    });

    tearDown(() async {
      await processing?.process();
      processing?.dispose();
      await db.close();
      await tempDir.delete(recursive: true);
    });

    test("processes downloaded pdfs from new to old", () async {
      await insertScore("old", lastOpened: DateTime.utc(2026, 2, 1));
      await insertScore("new", lastOpened: DateTime.utc(2026, 4, 1));
      await insertScore("middle", lastOpened: DateTime.utc(2026, 3, 1));
      await insertScore("remote", fileDownloaded: false);
      await insertScore("other", fileType: FileType.byName("png"));

      await start().process();

      expect(service.processed, ["new", "middle", "old"]);
      final processed = await row("new");
      expect(
        processed.processingVersion,
        ScoreProcessingRepository.processingVersion,
      );
      expect(processed.backgroundColor, 0xFF000000 | "new".hashCode);
      expect((await row("remote")).processingVersion, isNull);
      expect((await row("other")).processingVersion, isNull);
    });

    test("only reprocesses outdated versions", () async {
      await insertScore(
        "current",
        processingVersion: ScoreProcessingRepository.processingVersion,
      );
      await insertScore(
        "outdated",
        processingVersion: ScoreProcessingRepository.processingVersion - 1,
      );

      await start().process();

      expect(service.processed, ["outdated"]);
    });

    test("drops the result when the file changed meanwhile", () async {
      await insertScore("a");
      final gate = service.blocked["a"] = Completer();

      final run = start().process();
      await pumpEventQueue();
      await db.managers.scoresTable
          .filter((f) => f.id("a"))
          .update((o) => o(fileUpdatedAt: Value(DateTime.utc(2026, 5, 1))));
      gate.complete();
      service.blocked.clear();
      await run;

      expect(service.processed, ["a", "a"]);
      expect(
        (await row("a")).processingVersion,
        ScoreProcessingRepository.processingVersion,
      );
    });

    test("failures are retried once the file changes", () async {
      await insertScore("broken");
      service.failing.add("broken");

      await start().process();
      await processing!.process();
      expect(service.processed, ["broken"]);
      expect((await row("broken")).processingVersion, isNull);

      service.failing.clear();
      final replacement = File("${tempDir.path}/replacement.pdf");
      await replacement.writeAsString("%PDF-1.4 new");
      await scoresRepo.updateScoreFile("broken", XFile(replacement.path));
      await processing!.process();

      expect(service.processed, ["broken", "broken"]);
      expect(
        (await row("broken")).processingVersion,
        ScoreProcessingRepository.processingVersion,
      );
    });

    test("results leave the metadata untouched", () async {
      await insertScore("a");
      await db.managers.scoresTable.update(
        (o) => o(metadataUploaded: const Value(true)),
      );
      final localChanges = <Set<String>>[];
      final subscription = scoresRepo.locallyUpdatedScoreIds.listen(
        localChanges.add,
      );

      await start().process();
      await pumpEventQueue();
      await subscription.cancel();

      final processed = await row("a");
      expect(processed.metadataUploaded, isTrue);
      expect(processed.metadataUpdatedAt, timestamp);
      expect(localChanges, isEmpty);
    });

    test("processing requests start a run", () async {
      await start().process();
      await insertScore("synced");

      scoresRepo.requestProcessing({"synced"});
      await pumpEventQueue();
      await processing!.process();

      expect(service.processed, ["synced"]);
    });

    test("changing the file resets the processing result", () async {
      await insertScore(
        "a",
        processingVersion: ScoreProcessingRepository.processingVersion,
      );
      await db.managers.scoresTable
          .filter((f) => f.id("a"))
          .update((o) => o(backgroundColor: const Value(0xFFFFFFFF)));
      final replacement = File("${tempDir.path}/replacement.pdf");
      await replacement.writeAsString("%PDF-1.4 new");

      await scoresRepo.updateScoreFile("a", XFile(replacement.path));

      final updated = await row("a");
      expect(updated.processingVersion, isNull);
      expect(updated.backgroundColor, isNull);
    });

    test("new scores are processed after import", () async {
      start();
      await processing!.process();
      final file = File("${tempDir.path}/new.pdf");
      await file.writeAsString("%PDF-1.4");

      final scores = await scoresRepo.importAll([
        XFile(file.path),
      ], status: ScoreStatus.created);
      await pumpEventQueue();
      await processing!.process();

      expect(service.processed, [scores.single.id]);
      final score = (await scoresRepo.getScore(scores.single.id))!;
      expect(
        score.backgroundColor?.toARGB32(),
        (await row(score.id)).backgroundColor,
      );
    });
  });
}
