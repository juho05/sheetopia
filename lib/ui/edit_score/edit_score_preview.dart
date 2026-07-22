/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/annotate/annotation_painter.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScorePreview extends StatefulWidget {
  final Score score;

  const EditScorePreview({super.key, required this.score});

  @override
  State<EditScorePreview> createState() => _EditScorePreviewState();
}

class _EditScorePreviewState extends State<EditScorePreview> {
  PdfDocumentRefFile? pdfRef;

  late final ScoresRepository _scoresRepo;
  final Map<int, List<Stroke>> _annotations = {};
  StreamSubscription? _annotationsSub;

  @override
  void initState() {
    super.initState();
    if (widget.score.file != null && widget.score.fileType == FileType.pdf) {
      pdfRef = PdfDocumentRefFile(
        widget.score.file!.path,
        autoDispose: true,
        key: PdfDocumentRefKey(
          "${widget.score.file!.path}-${widget.score.fileUpdatedAt}",
        ),
      );
    }
    _scoresRepo = context.read<ScoresRepository>();
    _loadAnnotations();
    _annotationsSub = _scoresRepo.updatedScoreIds
        .where((s) => s.any((id) => id == widget.score.id))
        .listen((_) => _loadAnnotations());
  }

  Future<void> _loadAnnotations() async {
    final pages = await _scoresRepo.getAnnotations(widget.score.id);
    if (!mounted) return;
    setState(() {
      _annotations
        ..clear()
        ..addAll(pages);
    });
  }

  void _paintPage(Canvas canvas, Rect pageRect, PdfPage page) {
    final strokes = _annotations[page.pageNumber - 1];
    if (strokes == null || strokes.isEmpty) return;
    canvas.save();
    canvas.translate(pageRect.left, pageRect.top);
    AnnotationPainter(strokes: strokes).paint(canvas, pageRect.size);
    canvas.restore();
  }

  @override
  void didUpdateWidget(covariant EditScorePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score.file != null &&
        widget.score.fileType == FileType.pdf &&
        (oldWidget.score.fileUpdatedAt != widget.score.fileUpdatedAt ||
            oldWidget.score.file == null && widget.score.file != null)) {
      pdfRef = PdfDocumentRefFile(
        widget.score.file!.path,
        autoDispose: true,
        key: PdfDocumentRefKey(
          "${widget.score.file!.path}-${widget.score.fileUpdatedAt}",
        ),
      );
    }
    if (oldWidget.score.id != widget.score.id) {
      _annotationsSub?.cancel();
      _annotationsSub = _scoresRepo.updatedScoreIds
          .where((s) => s.any((id) => id == widget.score.id))
          .listen((_) => _loadAnnotations());
      _loadAnnotations();
    }
  }

  @override
  void dispose() {
    _annotationsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.score.file == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Stack(
      children: [
        switch (widget.score.fileType) {
          FileType.pdf => PdfViewer(
            pdfRef!,
            params: PdfViewerParams(
              interactionDelegateProvider:
                  const PdfViewerScrollInteractionDelegateProviderPhysics(),
              scrollPhysics: const ClampingScrollPhysics(),
              scrollByMouseWheel: 1,
              scaleByPointerScale: 0.8,
              pagePaintCallbacks: [_paintPage],
            ),
          ),
        },
        Consumer<EditScoreViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isImport) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topRight,
              child: Builder(
                builder: (context) {
                  Future<void> save() async {
                    if (!await viewModel.save()) return;
                    if (!context.mounted) return;
                    Toast.show("Successfully saved score file!");
                  }

                  Future<void> share() async {
                    Rect? sharePositionOrigin;
                    if (Platform.isIOS) {
                      final box = context.findRenderObject() as RenderBox?;
                      sharePositionOrigin =
                          box!.localToGlobal(Offset.zero) & box.size;
                    }
                    await viewModel.share(
                      sharePositionOrigin: sharePositionOrigin,
                    );
                  }

                  return Platform.isIOS
                      ? IconButton(
                          onPressed: () {
                            share();
                          },
                          color: Colors.white,
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.black.withAlpha(100),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.share),
                        )
                      : Platform.isAndroid
                      ? MenuAnchor(
                          builder: (context, controller, child) =>
                              IconButton.filled(
                                color: Colors.white,
                                iconSize: 20,
                                padding: const EdgeInsets.all(8),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                    Colors.black.withAlpha(100),
                                  ),
                                ),
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                icon: const Icon(Icons.share),
                              ),
                          menuChildren: [
                            MenuItemButton(
                              onPressed: () {
                                share();
                              },
                              trailingIcon: const Icon(Icons.share),
                              child: const Text("Share"),
                            ),
                            MenuItemButton(
                              onPressed: () {
                                save();
                              },
                              trailingIcon: const Icon(Icons.save_alt),
                              child: const Text("Export"),
                            ),
                          ],
                        )
                      : IconButton(
                          onPressed: () {
                            save();
                          },
                          icon: const Icon(Icons.save_alt),
                          color: Colors.white,
                          iconSize: 20,
                          padding: const EdgeInsets.all(8),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.black.withAlpha(100),
                            ),
                          ),
                        );
                },
              ),
            );
          },
        ),
        Consumer<EditScoreViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isImport) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                  onPressed: () =>
                      context.read<EditScoreViewModel>().changeFile(),
                  icon: const Icon(Icons.edit),
                  label: const Text("Change"),
                ),
              ),
            );
          },
        ),
        Consumer<EditScoreViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isImport ||
                widget.score.file == null ||
                widget.score.fileType != FileType.pdf) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                  onPressed: () =>
                      context.go('/scores/${widget.score.id}/edit/annotate'),
                  icon: const Icon(Icons.draw),
                  label: const Text("Annotate"),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
