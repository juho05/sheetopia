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
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/pdf_validation_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_surface.dart';

import 'dispose_with_tree.dart';

const _left = Offset(200, 300);
const _right = Offset(600, 300);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Database db;
  late AnnotateViewModel viewModel;
  late bool disposed;

  setUp(() async {
    db = Database(NativeDatabase.memory());
    final repo = ScoresRepository(
      db: db,
      thumbnailService: ThumbnailService(),
      pdfValidationService: const PdfValidationService(),
    );
    await db.managers.scoresTable.create(
      (o) => o(
        id: "a",
        title: "Title",
        searchText: " title ",
        fileDownloaded: false,
        fileType: FileType.pdf,
      ),
    );
    viewModel = AnnotateViewModel(repo: repo, scoreId: "a", drawMode: true);
    disposed = false;
  });

  void disposeViewModel() {
    if (disposed) return;
    disposed = true;
    viewModel.dispose();
  }

  tearDown(() async {
    disposeViewModel();
    await db.close();
  });

  Future<void> pumpPages(WidgetTester tester, {bool rightPage = true}) {
    return tester.pumpWidget(
      DisposeWithTree(
        onDispose: disposeViewModel,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: AnnotationSurface(viewModel: viewModel, pageIndex: 0),
              ),
              Expanded(
                child: rightPage
                    ? AnnotationSurface(viewModel: viewModel, pageIndex: 1)
                    : const SizedBox.expand(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> moveBoth(TestGesture a, TestGesture b) async {
    for (var i = 0; i < 5; i++) {
      await a.moveBy(const Offset(20, 10));
      await b.moveBy(const Offset(-20, 15));
    }
  }

  testWidgets("a finger on the other page is ignored while a stylus draws", (
    tester,
  ) async {
    await pumpPages(tester);
    final stylus = await tester.startGesture(
      _left,
      kind: PointerDeviceKind.stylus,
    );
    final finger = await tester.startGesture(_right);
    await moveBoth(stylus, finger);
    await finger.up();
    await stylus.up();
    await tester.pump();

    expect(viewModel.strokesFor(0), hasLength(1));
    expect(viewModel.strokesFor(1), isEmpty);
  });

  testWidgets("a stylus takes over from a finger on the other page", (
    tester,
  ) async {
    await pumpPages(tester);
    final finger = await tester.startGesture(_right);
    await finger.moveBy(const Offset(-20, 15));
    final stylus = await tester.startGesture(
      _left,
      kind: PointerDeviceKind.stylus,
    );
    await moveBoth(stylus, finger);
    await stylus.up();
    await finger.up();
    await tester.pump();

    expect(viewModel.strokesFor(0), hasLength(1));
    expect(viewModel.strokesFor(1), isEmpty);
  });

  testWidgets("a stylus takes over from a finger on the same page", (
    tester,
  ) async {
    await pumpPages(tester);
    final finger = await tester.startGesture(_left);
    await finger.moveBy(const Offset(20, 10));
    final stylus = await tester.startGesture(
      _left + const Offset(0, 100),
      kind: PointerDeviceKind.stylus,
    );
    await moveBoth(stylus, finger);
    await finger.up();
    await stylus.up();
    await tester.pump();

    final strokes = viewModel.strokesFor(0);
    expect(strokes, hasLength(1));
    expect(strokes.single.points.first.y, greaterThan(0.6));
  });

  testWidgets("the first finger keeps the stroke", (tester) async {
    await pumpPages(tester);
    final first = await tester.startGesture(_left);
    final second = await tester.startGesture(_right);
    await moveBoth(first, second);
    await second.up();
    await first.up();
    await tester.pump();

    expect(viewModel.strokesFor(0), hasLength(1));
    expect(viewModel.strokesFor(1), isEmpty);
  });

  testWidgets("a page removed mid-stroke does not block drawing", (
    tester,
  ) async {
    await pumpPages(tester);
    final finger = await tester.startGesture(_right);
    await finger.moveBy(const Offset(-20, 15));
    await pumpPages(tester, rightPage: false);
    await finger.up();

    final next = await tester.startGesture(_left);
    await next.moveBy(const Offset(40, 40));
    await next.moveBy(const Offset(40, 40));
    await next.up();
    await tester.pump();

    expect(viewModel.strokesFor(0), hasLength(1));
    expect(viewModel.strokesFor(1), isEmpty);
  });
}
