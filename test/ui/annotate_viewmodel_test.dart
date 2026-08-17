/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:ui';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';

const _scoreId = 'score-1';
const _aspect = 1.4;

StrokePoint _p(double x, double y) => StrokePoint(x: x, y: y, pressure: 0.5);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late ScoresRepository repo;
  late AnnotateViewModel viewModel;

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    await db.managers.scoresTable.create(
      (o) => o(
        id: _scoreId,
        title: "Title",
        searchText: " title ",
        fileDownloaded: false,
        fileType: FileType.pdf,
      ),
    );
    viewModel = AnnotateViewModel(repo: repo, scoreId: _scoreId);
    await pumpEventQueue();
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  void draw(int page, List<Offset> points) {
    viewModel.startStroke(page, _p(points.first.dx, points.first.dy), _aspect);
    for (final point in points.skip(1)) {
      viewModel.appendPoint(_p(point.dx, point.dy), _aspect);
    }
    viewModel.endStroke();
  }

  // A square lasso, drawn edge by edge so the samples clear the decimation
  // threshold.
  void lassoRect(int page, Rect rect) {
    viewModel.setLasso();
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    viewModel.startStroke(page, _p(corners.first.dx, corners.first.dy), _aspect);
    for (var i = 1; i <= corners.length; i++) {
      final from = corners[i - 1];
      final to = corners[i % corners.length];
      for (var s = 1; s <= 10; s++) {
        final t = s / 10;
        viewModel.appendPoint(
          _p(from.dx + (to.dx - from.dx) * t, from.dy + (to.dy - from.dy) * t),
          _aspect,
        );
      }
    }
    viewModel.endStroke();
  }

  void drag(int page, Offset from, Offset to) {
    viewModel.startStroke(page, _p(from.dx, from.dy), _aspect);
    viewModel.appendPoint(_p(to.dx, to.dy), _aspect);
    viewModel.endStroke();
  }

  group('lasso selection', () {
    test('selects only the strokes it encloses', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      draw(0, const [Offset(0.8, 0.8), Offset(0.9, 0.9)]);

      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));

      expect(viewModel.hasSelection, isTrue);
      expect(viewModel.selectionFor(0)!.strokes.length, 1);
      expect(
        viewModel.selectionFor(0)!.strokes.first.bounds.minX,
        closeTo(0.3, 0.02),
      );
    });

    test('a lasso around nothing leaves no selection', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.6, 0.6, 0.9, 0.9));
      expect(viewModel.hasSelection, isFalse);
    });

    test('a tap is not a lasso', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      viewModel.setLasso();
      viewModel.startStroke(0, _p(0.35, 0.35), _aspect);
      viewModel.endStroke();
      expect(viewModel.hasSelection, isFalse);
    });

    test('a lasso on another page replaces the selection', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      draw(1, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);

      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      expect(viewModel.selectionFor(0), isNotNull);

      lassoRect(1, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      expect(viewModel.selectionFor(0), isNull);
      expect(viewModel.selectionFor(1), isNotNull);
    });

    test('switching tool clears the selection', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      viewModel.setColor(AnnotateViewModel.blue);
      expect(viewModel.hasSelection, isFalse);
      expect(viewModel.tool, AnnotateTool.pen);
    });
  });

  group('move', () {
    test('shifts the strokes and keeps their z-order', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      draw(0, const [Offset(0.31, 0.31), Offset(0.41, 0.41)]);
      final second = viewModel.strokesFor(0)[1];

      lassoRect(0, const Rect.fromLTRB(0.28, 0.28, 0.45, 0.45));
      expect(viewModel.selectionFor(0)!.strokes.length, 2);

      drag(0, const Offset(0.35, 0.35), const Offset(0.45, 0.35));

      final moved = viewModel.strokesFor(0);
      expect(moved.length, 2);
      expect(moved[1].bounds.minX, closeTo(second.bounds.minX + 0.1, 1e-4));
      expect(moved[1].bounds.minY, closeTo(second.bounds.minY, 1e-4));
      // The selection survives the commit, zeroed, ready for another drag.
      expect(viewModel.dragOffset.value, Offset.zero);
      expect(identical(viewModel.selectionFor(0)!.strokes[1], moved[1]), isTrue);
    });

    test('undo restores the originals in place, redo re-applies', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      final before = viewModel.strokesFor(0).first;

      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      drag(0, const Offset(0.35, 0.35), const Offset(0.45, 0.35));
      final after = viewModel.strokesFor(0).first;
      expect(identical(after, before), isFalse);

      viewModel.undo();
      expect(identical(viewModel.strokesFor(0).first, before), isTrue);
      expect(viewModel.hasSelection, isFalse);

      viewModel.redo();
      expect(identical(viewModel.strokesFor(0).first, after), isTrue);
    });

    test('a tap inside the selection commits nothing', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      final undoDepth = viewModel.canUndo;
      final stroke = viewModel.strokesFor(0).first;

      drag(0, const Offset(0.35, 0.35), const Offset(0.35, 0.35));

      expect(viewModel.canUndo, undoDepth);
      expect(identical(viewModel.strokesFor(0).first, stroke), isTrue);
      expect(viewModel.hasSelection, isTrue);
    });

    test('a pointer down outside the selection deselects', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));

      viewModel.startStroke(0, _p(0.9, 0.9), _aspect);
      expect(viewModel.hasSelection, isFalse);
      viewModel.endStroke();
    });

    test('a drag cannot push the strokes off the page', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));

      viewModel.startStroke(0, _p(0.35, 0.35), _aspect);
      viewModel.appendPoint(_p(1.0, 1.0), _aspect);
      final offset = viewModel.dragOffset.value;
      viewModel.endStroke();

      expect(offset.dx, lessThan(0.65));
      expect(offset.dy, lessThan(0.65));

      final moved = viewModel.strokesFor(0).first;
      final outline = moved.outline;
      for (var i = 0; i + 1 < outline.length; i += 2) {
        expect(outline[i], lessThanOrEqualTo(1.0));
        expect(outline[i + 1], lessThanOrEqualTo(1.0));
      }
      // Still flush against the edge, not held back short of it.
      expect(moved.bounds.maxX, closeTo(1 - moved.width / 2, 0.01));
    });
  });

  group('delete', () {
    test('undo restores the strokes at their original indices', () {
      draw(0, const [Offset(0.1, 0.1), Offset(0.15, 0.15)]);
      draw(0, const [Offset(0.3, 0.3), Offset(0.35, 0.35)]);
      draw(0, const [Offset(0.6, 0.6), Offset(0.65, 0.65)]);
      final original = List.of(viewModel.strokesFor(0));

      lassoRect(0, const Rect.fromLTRB(0.25, 0.25, 0.45, 0.45));
      viewModel.deleteSelection();

      final remaining = viewModel.strokesFor(0);
      expect(remaining.length, 2);
      expect(identical(remaining[0], original[0]), isTrue);
      expect(identical(remaining[1], original[2]), isTrue);
      expect(viewModel.hasSelection, isFalse);

      viewModel.undo();
      final restored = viewModel.strokesFor(0);
      expect(restored.length, 3);
      for (var i = 0; i < 3; i++) {
        expect(identical(restored[i], original[i]), isTrue);
      }
    });
  });

  group('clipboard', () {
    setUp(() => viewModel.pageAspect = (_) => _aspect);

    test('cut removes from the source page and paste adds to the target', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));

      viewModel.cutSelection();
      expect(viewModel.strokesFor(0), isEmpty);
      expect(viewModel.canPaste, isTrue);

      viewModel.pasteInto(2);
      final pasted = viewModel.strokesFor(2);
      expect(pasted.length, 1);
      // Same page shape, so the paste is verbatim.
      expect(pasted.first.bounds.minX, closeTo(0.3, 0.02));
      expect(viewModel.selectionFor(2)!.strokes.length, 1);
    });

    test('copy leaves the page and the selection alone', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      final undoable = viewModel.canUndo;

      viewModel.copySelection();
      expect(viewModel.strokesFor(0).length, 1);
      expect(viewModel.hasSelection, isTrue);
      expect(viewModel.canUndo, undoable);
    });

    test('copy then paste on the same page duplicates, nudged', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      final source = viewModel.strokesFor(0).first;

      viewModel.copySelection();
      viewModel.pasteInto(0);

      final strokes = viewModel.strokesFor(0);
      expect(strokes.length, 2);
      expect(identical(strokes[1], source), isFalse);
      expect(strokes[1].bounds.minX, greaterThan(source.bounds.minX));
    });

    test('pasting twice stacks the copies apart', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      viewModel.cutSelection();

      viewModel.pasteInto(1);
      viewModel.pasteInto(1);

      final strokes = viewModel.strokesFor(1);
      expect(strokes.length, 2);
      expect(strokes[1].bounds.minX, greaterThan(strokes[0].bounds.minX));
    });

    test('one paste is one undo step', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      draw(0, const [Offset(0.32, 0.32), Offset(0.42, 0.42)]);
      lassoRect(0, const Rect.fromLTRB(0.25, 0.25, 0.5, 0.5));
      viewModel.copySelection();

      viewModel.pasteInto(1);
      expect(viewModel.strokesFor(1).length, 2);

      viewModel.undo();
      expect(viewModel.strokesFor(1), isEmpty);

      viewModel.redo();
      expect(viewModel.strokesFor(1).length, 2);
    });

    test('clearAll wipes the pages but keeps the clipboard', () {
      draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
      lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
      viewModel.cutSelection();

      viewModel.clearAll();
      expect(viewModel.hasAnnotations, isFalse);
      expect(viewModel.canPaste, isTrue);

      viewModel.pasteInto(0);
      expect(viewModel.strokesFor(0).length, 1);
    });

    test('a taller target page compresses the paste', () {
      draw(0, const [Offset(0.2, 0.2), Offset(0.2, 0.6)]);
      lassoRect(0, const Rect.fromLTRB(0.1, 0.1, 0.5, 0.7));
      viewModel.copySelection();

      viewModel.pageAspect = (page) => page == 1 ? _aspect * 2 : _aspect;
      viewModel.pasteInto(1);

      final source = viewModel.strokesFor(0).first.bounds;
      final pasted = viewModel.strokesFor(1).first.bounds;
      expect(
        pasted.maxY - pasted.minY,
        closeTo((source.maxY - source.minY) / 2, 1e-3),
      );
      expect(viewModel.strokesFor(1).first.width, closeTo(0.004 / 2, 1e-6));
    });
  });

  test('a move survives a save/reload round trip', () async {
    draw(0, const [Offset(0.3, 0.3), Offset(0.4, 0.4)]);
    lassoRect(0, const Rect.fromLTRB(0.2, 0.2, 0.5, 0.5));
    drag(0, const Offset(0.35, 0.35), const Offset(0.45, 0.35));
    final moved = viewModel.strokesFor(0).first.bounds;

    await viewModel.saveAll();

    final reloaded = AnnotateViewModel(repo: repo, scoreId: _scoreId);
    await pumpEventQueue();
    expect(reloaded.strokesFor(0).first.bounds.minX, closeTo(moved.minX, 1e-5));
    reloaded.dispose();
  });
}
