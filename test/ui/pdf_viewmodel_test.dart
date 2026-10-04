/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/score/pdf_viewmodel.dart';

class _FakePage extends Fake implements PdfPage {
  @override
  final int pageNumber;

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
  @override
  Stream<Set<String>> get updatedScoreIds => const Stream.empty();

  @override
  Future<Map<int, List<Stroke>>> getAnnotations(String scoreId) async => {};
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
  }) async {
    viewModel = PdfViewModel(
      file: File(_a),
      scoresRepository: _FakeScoresRepository(),
      scoreId: "a",
      gradual: gradual,
      nextPath: nextPath,
      previousPath: previousPath,
      nextScoreId: nextScoreId,
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
}
