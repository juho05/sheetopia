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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_surface.dart';
import 'package:sheetopia/ui/score/annotation_mode.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group("view transform", () {
    late ViewTransform transform;

    setUp(() {
      transform = ViewTransform()..viewport = const Size(400, 600);
    });

    test("does not zoom out below the viewport", () {
      transform.value = Matrix4.identity()..scaleByDouble(0.5, 0.5, 0.5, 1);
      expect(transform.scale, 1);
      expect(transform.offset, Offset.zero);
    });

    test("caps the zoom", () {
      transform.value = Matrix4.identity()..scaleByDouble(20, 20, 20, 1);
      expect(transform.scale, ViewTransform.maxScale);
    });

    test("keeps the scene inside the viewport", () {
      transform.value = Matrix4.identity()
        ..translateByDouble(50, -5000, 0, 1)
        ..scaleByDouble(2, 2, 2, 1);
      expect(transform.scale, 2);
      expect(transform.offset, const Offset(0, -600));
    });

    test("only notifies on an actual change", () {
      var notified = 0;
      transform.addListener(() => notified++);
      transform.reset();
      expect(notified, 0);
      transform.value = Matrix4.identity()..scaleByDouble(2, 2, 2, 1);
      transform.reset();
      expect(notified, 2);
    });
  });

  group("entering by stylus", () {
    late Database db;
    late AnnotationMode mode;

    setUp(() async {
      db = Database(NativeDatabase.memory());
      final repo = ScoresRepository(
        db: db,
        thumbnailService: ThumbnailService(),
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
      mode = AnnotationMode(repo: repo);
    });

    tearDown(() async {
      mode.dispose();
      await db.close();
    });

    Future<void> pumpSurface(WidgetTester tester) {
      return tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListenableBuilder(
            listenable: mode,
            builder: (context, _) => AnnotationSurface(
              viewModel: mode.viewModel,
              pageIndex: 0,
              onStylusDown: (event) => mode.enter(
                scoreId: "a",
                pages: {},
                toolbarAtTop: false,
                byStylus: true,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets("a tap enters without a stroke", (tester) async {
      await pumpSurface(tester);
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      expect(mode.active, isTrue);
      await gesture.up();
      await tester.pump();

      expect(mode.viewModel!.hasAnnotations, isFalse);
      expect(mode.viewModel!.drawMode, isFalse);
    });

    testWidgets("a drag is already the first stroke", (tester) async {
      await pumpSurface(tester);
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await gesture.moveBy(const Offset(40, 40));
      await gesture.moveBy(const Offset(40, 40));
      await gesture.up();
      await tester.pump();

      expect(mode.viewModel!.strokesFor(0), hasLength(1));
    });

    testWidgets("holding still snaps the stroke to a shape", (tester) async {
      await pumpSurface(tester);
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      await gesture.moveBy(const Offset(60, 35));
      await gesture.moveBy(const Offset(60, 45));
      await tester.pump(const Duration(milliseconds: 900));
      await gesture.moveBy(const Offset(3, 3));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveBy(const Offset(100, 0));
      await gesture.up();
      await tester.pump();

      final size = tester.getSize(find.byType(AnnotationSurface));
      final points = mode.viewModel!.strokesFor(0).single.points;
      final slope = (183 - 100) / size.height / ((323 - 100) / size.width);
      expect(points.last.x, closeTo(323 / size.width, 1e-4));
      for (final p in points) {
        expect(
          p.y - points.first.y,
          closeTo((p.x - points.first.x) * slope, 1e-4),
        );
      }
    });

    testWidgets("a stroke that keeps moving stays freehand", (tester) async {
      await pumpSurface(tester);
      final gesture = await tester.startGesture(
        const Offset(100, 100),
        kind: PointerDeviceKind.stylus,
      );
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(30, 10));
        await tester.pump(const Duration(milliseconds: 800));
      }
      await gesture.moveBy(const Offset(0, 100));
      await gesture.up();
      await tester.pump();

      final bounds = mode.viewModel!.strokesFor(0).single.bounds;
      final size = tester.getSize(find.byType(AnnotationSurface));
      expect(bounds.maxX, lessThan(230 / size.width));
    });

    testWidgets("a finger does not enter", (tester) async {
      await pumpSurface(tester);
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(40, 40));
      await gesture.up();

      expect(mode.active, isFalse);
    });

    testWidgets("without a stylus the draw mode starts like on the annotate "
        "page", (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final byStylus = mode.enter(
        scoreId: "a",
        pages: {},
        toolbarAtTop: false,
        byStylus: true,
      );
      expect(byStylus.drawMode, isFalse);
      mode.exit();

      final byShortcut = mode.enter(
        scoreId: "a",
        pages: {},
        toolbarAtTop: false,
        byStylus: false,
      );
      expect(byShortcut.drawMode, isTrue);
      debugDefaultTargetPlatformOverride = null;
      await tester.pump();
    });

    testWidgets("the tools survive leaving and entering again", (tester) async {
      final first = mode.enter(
        scoreId: "a",
        pages: {},
        toolbarAtTop: false,
        byStylus: true,
      );
      first.setColor(AnnotateViewModel.blue);
      mode.exit();
      await tester.pump();

      final second = mode.enter(
        scoreId: "a",
        pages: {},
        toolbarAtTop: true,
        byStylus: true,
      );
      expect(second.colorValue, AnnotateViewModel.blue);
      expect(mode.toolbarAtTop, isTrue);
    });
  });
}
