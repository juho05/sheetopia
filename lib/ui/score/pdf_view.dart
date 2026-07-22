/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/annotate/annotation_painter.dart';
import 'package:sheetopia/ui/score/pdf_viewmodel.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';

class PdfView extends StatefulWidget {
  final File file;
  final String scoreId;
  final int switchToken;
  final int switchSettleCount;

  final void Function()? onOpenSetlist;

  const PdfView({
    super.key,
    required this.file,
    required this.scoreId,
    required this.switchToken,
    required this.switchSettleCount,
    this.onOpenSetlist,
  });

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  late final PdfViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final scoreViewModel = context.read<ScoreViewModel>();
    _viewModel = PdfViewModel(
      file: widget.file,
      midiRepository: context.read(),
      scoreViewModel: scoreViewModel,
      scoresRepository: context.read(),
      scoreId: widget.scoreId,
    );
  }

  @override
  void didUpdateWidget(covariant PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.switchToken != oldWidget.switchToken ||
        widget.file.path != oldWidget.file.path) {
      _viewModel.updateFile(widget.file);
    }
    if (widget.scoreId != oldWidget.scoreId) {
      _viewModel.updateScoreId(widget.scoreId);
    }
    if (widget.switchSettleCount != oldWidget.switchSettleCount) {
      _viewModel.clearSwitchInFlight();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        double calcPageWidth(PdfPage page) {
          return constraints.maxHeight * (page.width / page.height);
        }

        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final pages = _viewModel.document?.pages ?? [];

            (int, double) calcPageCountAndGap(
              int startIndex, {
              bool reverse = false,
            }) {
              int pageCount = 0;
              double totalWidth = 0;
              while (startIndex + pageCount >= 0 &&
                  startIndex + pageCount < pages.length) {
                final newTotalWidth =
                    totalWidth + calcPageWidth(pages[startIndex + pageCount]);
                if (newTotalWidth > constraints.maxWidth &&
                    pageCount.abs() > 0) {
                  break;
                }
                if (reverse) {
                  pageCount--;
                } else {
                  pageCount++;
                }
                totalWidth = newTotalWidth;
              }

              pageCount = pageCount.abs();

              final gap = pageCount > 1
                  ? ((constraints.maxWidth - totalWidth) / (pageCount - 1))
                        .clamp(0.0, 16.0)
                  : 0.0;
              return (pageCount, gap);
            }

            final (pageCount, gap) = calcPageCountAndGap(
              _viewModel.currentPageIndex,
            );

            final (nextPageCount, nextGap) = calcPageCountAndGap(
              _viewModel.currentPageIndex + pageCount,
            );

            final (prevPageCount, _) = calcPageCountAndGap(
              _viewModel.currentPageIndex - 1,
              reverse: true,
            );

            _viewModel.updateForwardPageCount(pageCount);
            _viewModel.updateBackwardPageCount(prevPageCount);

            var loading = _viewModel.document == null || _viewModel.switching;

            if (_viewModel.needsLastSpreadStart && pages.isNotEmpty) {
              final (lastSpreadCount, _) = calcPageCountAndGap(
                pages.length - 1,
                reverse: true,
              );
              final start = max(0, pages.length - lastSpreadCount);
              final moving = start != _viewModel.currentPageIndex;
              _viewModel.updateLastSpreadStart(start);
              if (moving) loading = true;
            }

            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowUp):
                    _viewModel.prevPage,
                const SingleActivator(LogicalKeyboardKey.arrowDown):
                    _viewModel.nextPage,
                const SingleActivator(LogicalKeyboardKey.arrowLeft):
                    _viewModel.prevPage,
                const SingleActivator(LogicalKeyboardKey.arrowRight):
                    _viewModel.nextPage,
                const SingleActivator(LogicalKeyboardKey.pageUp):
                    _viewModel.prevPage,
                const SingleActivator(LogicalKeyboardKey.pageDown):
                    _viewModel.nextPage,
                const SingleActivator(LogicalKeyboardKey.space):
                    _viewModel.nextPage,
                const SingleActivator(LogicalKeyboardKey.enter):
                    _viewModel.nextPage,
                const SingleActivator(LogicalKeyboardKey.backspace):
                    _viewModel.prevPage,
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent &&
                      event.kind == PointerDeviceKind.mouse) {
                    if (event.scrollDelta.dy > 0) {
                      _viewModel.nextPage();
                    } else {
                      _viewModel.prevPage();
                    }
                  }
                },
                child: GestureDetector(
                  onVerticalDragEnd: widget.onOpenSetlist == null
                      ? null
                      : (details) {
                          final velocity = details.primaryVelocity;
                          if (velocity != null && velocity < -300) {
                            widget.onOpenSetlist!();
                          }
                        },
                  onTapUp: (details) {
                    if (details.localPosition.dx < constraints.maxWidth / 2) {
                      _viewModel.prevPage();
                    } else {
                      _viewModel.nextPage();
                    }
                  },
                  child: FocusScope(
                    autofocus: true,
                    child: Material(
                      color: Colors.transparent,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (loading)
                            const Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          // back layer
                          if (!loading && pageCount > 0 && nextPageCount > 0)
                            Row(
                              key: ValueKey(
                                "${_viewModel.currentPageIndex + pageCount}-${_viewModel.documentPath}",
                              ),
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: nextGap,
                              children: List.generate(nextPageCount, (index) {
                                final page =
                                    pages[_viewModel.currentPageIndex +
                                        pageCount +
                                        index];
                                return Flexible(
                                  child: Opacity(
                                    opacity: 0,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            constraints.maxHeight *
                                            (page.width / page.height),
                                      ),
                                      child: Stack(
                                        fit: StackFit.passthrough,
                                        children: [
                                          MediaQuery(
                                            data: mediaQuery.copyWith(
                                              devicePixelRatio: max(
                                                mediaQuery.devicePixelRatio,
                                                2.0,
                                              ),
                                            ),
                                            child: PdfPageView(
                                              document: _viewModel.document!,
                                              pageNumber: page.pageNumber,
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: AnnotationPainter(
                                                strokes: _viewModel
                                                    .strokesForPage(
                                                      page.pageNumber,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          // front layer
                          if (!loading)
                            Row(
                              key: ValueKey(
                                "${_viewModel.currentPageIndex}-${_viewModel.documentPath}",
                              ),
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: gap,
                              children: List.generate(pageCount, (index) {
                                final page =
                                    pages[_viewModel.currentPageIndex + index];
                                return Flexible(
                                  child: Opacity(
                                    opacity: 1,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            constraints.maxHeight *
                                            (page.width / page.height),
                                      ),
                                      child: Stack(
                                        fit: StackFit.passthrough,
                                        children: [
                                          MediaQuery(
                                            data: mediaQuery.copyWith(
                                              devicePixelRatio: max(
                                                mediaQuery.devicePixelRatio,
                                                2.0,
                                              ),
                                            ),
                                            child: PdfPageView(
                                              document: _viewModel.document!,
                                              pageNumber: page.pageNumber,
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: AnnotationPainter(
                                                strokes: _viewModel
                                                    .strokesForPage(
                                                      page.pageNumber,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
