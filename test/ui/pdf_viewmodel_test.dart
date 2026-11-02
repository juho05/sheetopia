/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/score_processing/page_margins.dart';
import 'package:sheetopia/ui/score/page_region.dart';
import 'package:sheetopia/ui/score/pdf_viewmodel.dart';

class _FakePage extends Fake implements PdfPage {
  @override
  final int pageNumber;

  @override
  double get width => 800;

  @override
  double get height => 800;

  _FakePage(this.pageNumber);
}

class _FakeDocument extends Fake implements PdfDocument {
  final String path;

  @override
  final List<PdfPage> pages;

  bool disposed = false;

  _FakeDocument(this.path, int pageCount)
    : pages = [for (var i = 1; i <= pageCount; i++) _FakePage(i)];

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _FakeEntryFunctions extends Fake implements PdfrxEntryFunctions {
  final Map<String, int> pageCounts;
  final List<_FakeDocument> opened = [];

  _FakeEntryFunctions(this.pageCounts);

  @override
  Future<PdfDocument> openFile(
    String filePath, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
  }) async {
    final document = _FakeDocument(filePath, pageCounts[filePath]!);
    opened.add(document);
    return document;
  }
}

class _FakeScoresRepository extends Fake implements ScoresRepository {
  final Map<String, PageMargins> margins = {};
  final Map<String, Map<int, List<Stroke>>> annotations = {};
  final StreamController<Set<String>> updates = StreamController.broadcast();
  final List<String> marginQueries = [];
  final Map<String, Completer<PageMargins?>> pendingMargins = {};
  final Map<String, Completer<Map<int, List<Stroke>>>> pendingAnnotations = {};
  bool failAnnotations = false;
  bool failMargins = false;

  @override
  Stream<Set<String>> get updatedScoreIds => updates.stream;

  @override
  Future<Map<int, List<Stroke>>> getAnnotations(String scoreId) async {
    if (failAnnotations) throw const FormatException();
    final pending = pendingAnnotations[scoreId];
    if (pending != null) return pending.future;
    return annotations[scoreId] ?? {};
  }

  @override
  Future<PageMargins?> getPageMargins(String scoreId) async {
    marginQueries.add(scoreId);
    if (failMargins) throw StateError("database closed");
    final pending = pendingMargins[scoreId];
    if (pending != null) return pending.future;
    return margins[scoreId];
  }
}

const _a = "/a.pdf";
const _b = "/b.pdf";

void main() {
  Log.init(LogRepository());
  Log.level = Level.off;

  late PdfrxEntryFunctions originalEntryFunctions;
  late _FakeEntryFunctions entryFunctions;
  late PdfViewModel viewModel;
  late List<bool> turns;
  late List<String> overflows;
  late bool canOverflow;
  late int pagesPerScreen;
  late _FakeScoresRepository repo;

  // mirrors the page counts PdfView reports on every build
  void layout() {
    final document = viewModel.document;
    if (document == null) return;
    final total =
        document.pages.length + (viewModel.spillDocument?.pages.length ?? 0);
    final index = viewModel.currentPageIndex;
    viewModel.updateForwardPageCount(min(pagesPerScreen, total - index));
    viewModel.updateBackwardPageCount(
      index > 0 ? min(pagesPerScreen, total - index + 1) : 0,
    );
  }

  Future<void> open({
    bool gradual = true,
    String? nextPath,
    String? previousPath,
    String? nextScoreId,
    String? previousScoreId,
    bool cropEnabled = false,
  }) async {
    viewModel = PdfViewModel(
      file: File(_a),
      scoresRepository: repo,
      cropEnabled: cropEnabled,
      cropPadding: 0.05,
      scoreId: "a",
      gradual: gradual,
      nextPath: nextPath,
      previousPath: previousPath,
      nextScoreId: nextScoreId,
      previousScoreId: previousScoreId,
      onOverflowForward: () {
        overflows.add("forward");
        return canOverflow;
      },
      onOverflowBackward: () {
        overflows.add("backward");
        return canOverflow;
      },
      onPageTurned: turns.add,
    );
    viewModel.addListener(layout);
    await pumpEventQueue();
  }

  // what ScoreViewer and PdfView do once the sequence has moved on
  Future<void> switchTo(
    String path,
    String scoreId, {
    String? nextPath,
    String? previousPath,
    String? nextScoreId,
  }) async {
    viewModel.updateFile(File(path));
    viewModel.updateScoreId(scoreId);
    viewModel.clearSwitchInFlight();
    viewModel.updateNeighbors(
      next: nextPath,
      previous: previousPath,
      nextScoreId: nextScoreId,
      settled: true,
    );
    await pumpEventQueue();
  }

  Future<void> next() async {
    viewModel.nextPage();
    await pumpEventQueue();
  }

  Future<void> prev() async {
    viewModel.prevPage();
    await pumpEventQueue();
  }

  (int, bool) state() => (viewModel.currentPageIndex, viewModel.half);

  setUp(() {
    originalEntryFunctions = PdfrxEntryFunctions.instance;
    entryFunctions = _FakeEntryFunctions({_a: 3, _b: 2});
    PdfrxEntryFunctions.instance = entryFunctions;
    turns = [];
    overflows = [];
    canOverflow = false;
    pagesPerScreen = 1;
    repo = _FakeScoresRepository();
  });

  tearDown(() {
    viewModel.dispose();
    PdfrxEntryFunctions.instance = originalEntryFunctions;
  });

  group("whole spreads", () {
    test("a turn moves by the pages on screen", () async {
      pagesPerScreen = 2;
      await open(gradual: false);

      await next();
      expect(state(), (2, false));
      await next();
      expect(state(), (2, false));
      expect(overflows, ["forward"]);

      await prev();
      expect(state(), (0, false));
      await prev();
      expect(overflows, ["forward", "backward"]);
      expect(turns, [true, false]);
    });
  });

  group("gradual, one page on screen", () {
    test("forward alternates between half and full pages", () async {
      await open();

      final seen = [state()];
      for (var i = 0; i < 4; i++) {
        await next();
        seen.add(state());
      }
      expect(seen, [(0, false), (0, true), (1, false), (1, true), (2, false)]);
      expect(turns, [true, true, true, true]);
      expect(overflows, isEmpty);
    });

    test("the last page overflows instead of going half", () async {
      await open();
      for (var i = 0; i < 4; i++) {
        await next();
      }
      turns.clear();

      await next();
      expect(state(), (2, false));
      expect(overflows, ["forward"]);
      expect(turns, isEmpty);
    });

    test("backward retraces the forward steps", () async {
      await open();
      for (var i = 0; i < 4; i++) {
        await next();
      }
      turns.clear();

      final seen = <(int, bool)>[];
      for (var i = 0; i < 4; i++) {
        await prev();
        seen.add(state());
      }
      expect(seen, [(1, true), (1, false), (0, true), (0, false)]);
      expect(turns, [false, false, false, false]);

      await prev();
      expect(state(), (0, false));
      expect(overflows, ["backward"]);
    });

    test("turning gradual off drops the half state", () async {
      await open();
      await next();
      expect(viewModel.half, isTrue);

      viewModel.updateGradual(false);
      expect(viewModel.half, isFalse);
    });

    test("the next score continues the last page", () async {
      canOverflow = true;
      await open(nextPath: _b, nextScoreId: "b");
      expect(viewModel.spillDocument, isNull);

      for (var i = 0; i < 4; i++) {
        await next();
      }
      expect(state(), (2, false));
      final spill = viewModel.spillDocument;
      expect(spill, isNotNull);

      await next();
      expect(state(), (2, true));
      expect(overflows, isEmpty);

      await next();
      expect(overflows, ["forward"]);
      expect(viewModel.switching, isFalse);

      await switchTo(_b, "b", previousPath: _a);
      expect(viewModel.document, same(spill));
      expect(state(), (0, false));
      expect(viewModel.spillDocument, isNull);
    });

    test("the spill stays available until the switch has landed", () async {
      canOverflow = true;
      await open(nextPath: _b, nextScoreId: "b");
      for (var i = 0; i < 6; i++) {
        await next();
      }
      final spill = viewModel.spillDocument;
      expect(spill, isNotNull);

      viewModel.updateFile(File(_b));
      expect(viewModel.spillDocument, same(spill));
      expect(state(), (2, true));

      await pumpEventQueue();
      expect(viewModel.document, same(spill));
    });

    test("turns are ignored while a switch is pending", () async {
      canOverflow = true;
      await open(nextPath: _b, nextScoreId: "b");
      for (var i = 0; i < 6; i++) {
        await next();
      }
      expect(overflows, ["forward"]);

      await next();
      await prev();
      expect(state(), (2, true));
      expect(overflows, ["forward"]);
    });

    test("going back lands half way into the previous score", () async {
      canOverflow = true;
      await open(nextPath: _b, nextScoreId: "b");
      final first = viewModel.document;
      for (var i = 0; i < 6; i++) {
        await next();
      }
      await switchTo(_b, "b", previousPath: _a);
      final second = viewModel.document;

      await prev();
      expect(overflows, ["forward", "backward"]);
      await switchTo(_a, "a", nextPath: _b, nextScoreId: "b");

      expect(viewModel.document, same(first));
      expect(viewModel.spillDocument, same(second));
      expect(state(), (2, true));
      expect(entryFunctions.opened.where((d) => d.disposed), isEmpty);

      await prev();
      expect(state(), (2, false));
      await prev();
      expect(state(), (1, true));
    });

    test("a failed switch releases the previous document", () async {
      await open(nextPath: "/missing.pdf", nextScoreId: "missing");
      final first = entryFunctions.opened.single;

      await switchTo("/missing.pdf", "missing", previousPath: _a);

      expect(viewModel.loadFailed, isTrue);
      expect(viewModel.document, isNull);
      expect(first.disposed, isTrue);
    });

    test("going back lands on a full page without a following score", () async {
      canOverflow = true;
      await open(previousPath: _b);

      await prev();
      expect(overflows, ["backward"]);
      await switchTo(_b, "b", nextPath: _a);

      expect(viewModel.spillDocument, isNull);
      expect(state(), (1, false));
    });
  });

  group("gradual, two pages on screen", () {
    setUp(() => pagesPerScreen = 2);

    test("a turn moves by a single page", () async {
      await open();

      await next();
      expect(state(), (1, false));

      await next();
      expect(state(), (1, false));
      expect(overflows, ["forward"]);

      await prev();
      expect(state(), (0, false));
      await prev();
      expect(overflows, ["forward", "backward"]);
      expect(turns, [true, false]);
    });

    test("the last page is shown next to the following score", () async {
      canOverflow = true;
      await open(nextPath: _b, nextScoreId: "b");

      await next();
      await next();
      expect(state(), (2, false));
      expect(overflows, isEmpty);

      await next();
      expect(overflows, ["forward"]);
      await switchTo(_b, "b", previousPath: _a);
      expect(state(), (0, false));

      await prev();
      await switchTo(_a, "a", nextPath: _b, nextScoreId: "b");
      expect(viewModel.currentPageIndex, 2);
      expect(viewModel.needsLastSpreadStart, isFalse);

      await prev();
      expect(state(), (1, false));
    });
  });

  group("crop", () {
    const margins = PageMargins(left: 0.2, top: 0.2, right: 0.2, bottom: 0.2);

    Stroke stroke(double x) => Stroke(
      colorValue: 0,
      width: 0.001,
      points: [StrokePoint(x: x, y: 0.5, pressure: 0.5)],
      outline: [x, 0.5],
    );

    PdfPage firstPage() => viewModel.document!.pages.first;

    test("shows the full page when disabled", () async {
      repo.margins["a"] = margins;
      await open();
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);
      expect(viewModel.cropPending, isFalse);
    });

    test("shows the full page without detected margins", () async {
      await open(cropEnabled: true);
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);
    });

    test("crops the margins minus the padding", () async {
      repo.margins["a"] = margins;
      await open(cropEnabled: true);
      final region = viewModel.visibleRegion(firstPage());
      expect(region.left, closeTo(0.15, 1e-9));
      expect(region.right, closeTo(0.85, 1e-9));
    });

    test("is pending until the margins are known", () async {
      repo.margins["a"] = margins;
      viewModel = PdfViewModel(
        file: File(_a),
        scoresRepository: repo,
        scoreId: "a",
        cropEnabled: true,
      );
      expect(viewModel.cropPending, isTrue);
      await pumpEventQueue();
      expect(viewModel.cropPending, isFalse);
    });

    test("spill pages use the crop of their own score", () async {
      repo.margins["a"] = margins;
      await open(cropEnabled: true, nextPath: _b, nextScoreId: "b");
      for (var i = 0; i < 4 && viewModel.spillDocument == null; i++) {
        await next();
      }

      expect(viewModel.spillDocument, isNotNull);
      expect(viewModel.visibleRegion(firstPage(), spill: true), fullPageRegion);
      expect(viewModel.visibleRegion(firstPage()), isNot(fullPageRegion));
    });

    test("strokes in the margin stay visible", () async {
      repo.margins["a"] = margins;
      repo.annotations["a"] = {
        2: [stroke(0.1)],
      };
      await open(cropEnabled: true);
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.1, 1e-9));
    });

    test("stays while annotating and follows the strokes after", () async {
      repo.margins["a"] = margins;
      repo.annotations["a"] = {
        0: [stroke(0.1)],
      };
      await open(cropEnabled: true);

      viewModel.annotating = true;
      viewModel.setAnnotations({"a": {}});
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.1, 1e-9));

      repo.annotations["a"] = {};
      repo.updates.add({"a"});
      await pumpEventQueue();
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.1, 1e-9));

      var notified = 0;
      viewModel.addListener(() => notified++);
      viewModel.annotating = false;
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.15, 1e-9));
      expect(notified, 1);
    });

    test(
      "failed annotations neither block the score nor enable editing",
      () async {
        repo.margins["a"] = margins;
        repo.failAnnotations = true;
        await open(cropEnabled: true);
        expect(viewModel.cropPending, isFalse);
        expect(viewModel.documentAnnotations, isNull);
        expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.15, 1e-9));
      },
    );

    test("failed margins show the full page", () async {
      repo.margins["a"] = margins;
      repo.failMargins = true;
      await open(cropEnabled: true);
      expect(viewModel.cropPending, isFalse);
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);
    });

    test("margins stay on score updates", () async {
      await open(cropEnabled: true);
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);

      repo.margins["a"] = margins;
      repo.updates.add({"a"});
      await pumpEventQueue();
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);
    });

    test("margins reload when the document is opened anew", () async {
      await open(gradual: false, cropEnabled: true);
      repo.margins["a"] = margins;

      viewModel.updateFile(File(_a));
      await pumpEventQueue();
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.15, 1e-9));
    });

    test("the last spread waits for the crop", () async {
      canOverflow = true;
      await open(gradual: false, cropEnabled: true, previousPath: _b);
      final pending = Completer<PageMargins?>();
      repo.pendingMargins["b"] = pending;

      await prev();
      expect(overflows, ["backward"]);
      viewModel.updateFile(File(_b));
      viewModel.updateScoreId("b");
      await pumpEventQueue();
      expect(viewModel.documentScoreId, "b");
      expect(viewModel.cropPending, isTrue);
      expect(viewModel.needsLastSpreadStart, isFalse);

      pending.complete(margins);
      await pumpEventQueue();
      expect(viewModel.cropPending, isFalse);
      expect(viewModel.needsLastSpreadStart, isTrue);
    });

    test("the crop of the neighbors is known ahead of the turn", () async {
      repo.margins["b"] = margins;
      await open(
        gradual: false,
        cropEnabled: true,
        nextPath: _b,
        nextScoreId: "b",
        previousPath: _b,
        previousScoreId: "c",
      );
      expect(repo.marginQueries, containsAll(["a", "b", "c"]));

      repo.marginQueries.clear();
      final pendingWhenShown = <bool>[];
      viewModel.addListener(() {
        if (viewModel.documentScoreId == "b") {
          pendingWhenShown.add(viewModel.cropPending);
        }
      });
      viewModel.updateFile(File(_b));
      viewModel.updateScoreId("b");
      await pumpEventQueue();

      expect(pendingWhenShown, isNotEmpty);
      expect(pendingWhenShown, everyElement(isFalse));
    });

    test("turning to a neighbor uses its current margins", () async {
      await open(
        gradual: false,
        cropEnabled: true,
        nextPath: _b,
        nextScoreId: "b",
      );
      expect(viewModel.documentScoreId, "a");

      repo.margins["b"] = margins;
      final regions = <Rect>[];
      viewModel.addListener(() {
        if (viewModel.documentScoreId == "b") {
          regions.add(viewModel.visibleRegion(firstPage()));
        }
      });
      viewModel.updateFile(File(_b));
      viewModel.updateScoreId("b");
      await pumpEventQueue();

      expect(regions, isNotEmpty);
      for (final region in regions) {
        expect(region.left, closeTo(0.15, 1e-9));
      }
    });

    test("spill pages on screen keep their crop when turned to", () async {
      await open(cropEnabled: true, nextPath: _b, nextScoreId: "b");
      repo.margins["b"] = margins;

      viewModel.updateFile(File(_b));
      viewModel.updateScoreId("b");
      await pumpEventQueue();
      expect(viewModel.documentScoreId, "b");
      expect(viewModel.visibleRegion(firstPage()), fullPageRegion);
    });

    test("turns wait for the crop", () async {
      final pending = repo.pendingMargins["a"] = Completer();
      await open(gradual: false, cropEnabled: true);
      layout();
      expect(viewModel.cropPending, isTrue);

      await next();
      expect(viewModel.currentPageIndex, 0);
      expect(turns, isEmpty);

      pending.complete(margins);
      await pumpEventQueue();
      await next();
      expect(viewModel.currentPageIndex, 1);
    });

    test("a load in flight does not replace newer strokes", () async {
      repo.margins["a"] = margins;
      await open(cropEnabled: true);

      final pending = repo.pendingAnnotations["a"] = Completer();
      repo.updates.add({"a"});
      await pumpEventQueue();

      viewModel.setAnnotations({
        "a": {
          0: [stroke(0.1)],
        },
      });
      pending.complete({});
      await pumpEventQueue();

      expect(viewModel.strokesForPage(1), hasLength(1));
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.1, 1e-9));
    });

    test("the crop survives the sequence moving ahead of the view", () async {
      await open(
        gradual: false,
        cropEnabled: true,
        nextPath: _b,
        nextScoreId: "b",
      );
      final pendingWhenShown = <bool>[];
      viewModel.addListener(() {
        if (viewModel.documentScoreId == "b") {
          pendingWhenShown.add(viewModel.cropPending);
        }
      });

      viewModel.updateNeighbors(
        previous: _a,
        previousScoreId: "a",
        settled: false,
      );
      await pumpEventQueue();
      viewModel.updateFile(File(_b));
      viewModel.updateScoreId("b");
      viewModel.updateNeighbors(
        previous: _a,
        previousScoreId: "a",
        settled: true,
      );
      await pumpEventQueue();

      expect(viewModel.documentScoreId, "b");
      expect(pendingWhenShown, isNotEmpty);
      expect(pendingWhenShown, everyElement(isFalse));
    });

    test("scores out of reach are dropped once settled", () async {
      await open(
        gradual: false,
        cropEnabled: true,
        nextPath: _b,
        nextScoreId: "b",
      );
      viewModel.updateNeighbors(settled: false);
      viewModel.updateNeighbors(settled: true);
      repo.marginQueries.clear();

      viewModel.updateNeighbors(next: _b, nextScoreId: "b", settled: true);
      await pumpEventQueue();
      expect(repo.marginQueries, ["b"]);
    });

    test("no crop work while disabled, it starts when enabled", () async {
      repo.margins["a"] = margins;
      await open();
      expect(repo.marginQueries, isEmpty);

      viewModel.updateCrop(enabled: true, padding: 0.05);
      expect(viewModel.cropPending, isTrue);
      await pumpEventQueue();
      expect(viewModel.cropPending, isFalse);
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.15, 1e-9));
    });

    test("the region follows the padding", () async {
      repo.margins["a"] = margins;
      await open(cropEnabled: true);
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.15, 1e-9));

      viewModel.updateCrop(enabled: true, padding: 0.1);
      expect(viewModel.visibleRegion(firstPage()).left, closeTo(0.1, 1e-9));
    });
  });
}
