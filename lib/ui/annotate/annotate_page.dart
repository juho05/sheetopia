/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/annotation_surface.dart';
import 'package:sheetopia/ui/annotate/annotation_toolbar.dart';
import 'package:sheetopia/ui/annotate/pan_zoom_overlay.dart';
import 'package:sheetopia/ui/common/overlay_icon_button.dart';

class AnnotatePage extends StatefulWidget {
  final String scoreId;

  const AnnotatePage({super.key, required this.scoreId});

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _PdfViewerTarget implements PanZoomTarget {
  final PdfViewerController controller;

  const _PdfViewerTarget(this.controller);

  @override
  bool get isReady => controller.isReady;

  @override
  Matrix4 get value => controller.value;

  @override
  set value(Matrix4 value) => controller.value = value;
}

class _AnnotatePageState extends State<AnnotatePage> {
  late final AnnotateViewModel _viewModel;

  final PdfViewerController _controller = PdfViewerController();

  PdfDocumentRefFile? _pdfRef;

  @override
  void initState() {
    super.initState();
    _viewModel = AnnotateViewModel(
      repo: context.read(),
      scoreId: widget.scoreId,
    );
    // The layout is authoritative for every page, laid out or not, unlike the
    // aspect the surfaces report.
    _viewModel.pageAspect = (index) {
      if (!_controller.isReady) return null;
      final pages = _controller.layout.pageLayouts;
      if (index < 0 || index >= pages.length) return null;
      final rect = pages[index];
      return rect.width <= 0 ? null : rect.height / rect.width;
    };
    _loadFile();
  }

  void _paste() {
    final page = _controller.isReady ? _controller.pageNumber : null;
    if (page != null) _viewModel.pasteInto(page - 1);
  }

  Future<void> _loadFile() async {
    final score = await context.read<ScoresRepository>().getScore(
      widget.scoreId,
    );
    if (!mounted) return;
    final file = score?.file;
    setState(() {
      _pdfRef = file == null
          ? null
          : PdfDocumentRefFile(file.path, autoDispose: true);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  double _currentPageMaxSidePx() {
    if (!_controller.isReady) return 0;
    final page = _controller.pageNumber;
    final pages = _controller.layout.pageLayouts;
    if (page == null || page < 1 || page > pages.length) return 0;
    final rect = pages[page - 1];
    return max(rect.width, rect.height) * _controller.value.getMaxScaleOnAxis();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _viewModel.saveAll();
        },
        child: CallbackShortcuts(
          bindings: {
            ...annotationShortcuts(_viewModel),
            const SingleActivator(
              LogicalKeyboardKey.escape,
              includeRepeats: false,
            ): _viewModel.clearSelection,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: SafeArea(
                child: Stack(
                  children: [
                    if (_pdfRef == null)
                      const Center(child: CircularProgressIndicator.adaptive())
                    else
                      PdfViewer(
                        _pdfRef!,
                        controller: _controller,
                        params: PdfViewerParams(
                          interactionDelegateProvider:
                              const PdfViewerScrollInteractionDelegateProviderPhysics(),
                          scrollPhysics: const ClampingScrollPhysics(),
                          // All pan/zoom/wheel is driven by PanZoomOverlay so a
                          // stylus can keep drawing while a finger navigates. pdfrx's
                          // own handling stays off; leaving the wheel enabled would
                          // double-handle it (pdfrx scrolls a ctrl+wheel while we
                          // zoom it, since it handles pointer signals directly).
                          panEnabled: false,
                          scaleEnabled: false,
                          textSelectionParams: const PdfTextSelectionParams(
                            enabled: false,
                          ),
                          pageOverlaysBuilder: (context, pageRect, page) => [
                            AnnotationSurface(
                              viewModel: _viewModel,
                              pageIndex: page.pageNumber - 1,
                            ),
                          ],
                        ),
                      ),
                    if (_pdfRef != null)
                      Positioned.fill(
                        child: PanZoomOverlay(
                          target: _PdfViewerTarget(_controller),
                          viewModel: _viewModel,
                        ),
                      ),
                    Positioned.fill(
                      child: AnnotationToolbar(
                        viewModel: _viewModel,
                        onPaste: _paste,
                        pageMaxSidePx: _currentPageMaxSidePx,
                      ),
                    ),
                    OverlayIconButton(
                      icon: const BackButtonIcon(),
                      onPressed: context.pop,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
