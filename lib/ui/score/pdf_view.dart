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
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/annotate/annotation_painter.dart';
import 'package:sheetopia/ui/score/pdf_viewmodel.dart';
import 'package:sheetopia/ui/score/score_file_view.dart';

class PdfView extends StatefulWidget {
  final File file;
  final String scoreId;
  final int switchToken;
  final int switchSettleCount;

  final ScoreFileViewController controller;

  final bool gradualPageTurns;

  final String? nextPath;
  final String? previousPath;

  final String? nextScoreId;
  final bool neighborsSettled;

  final bool Function()? onOverflowForward;
  final bool Function()? onOverflowBackward;
  final void Function(bool forward)? onPageTurned;
  final void Function()? onSwipeUp;

  const PdfView({
    super.key,
    required this.file,
    required this.scoreId,
    required this.switchToken,
    required this.switchSettleCount,
    required this.controller,
    this.gradualPageTurns = false,
    this.nextPath,
    this.previousPath,
    this.nextScoreId,
    this.neighborsSettled = true,
    this.onOverflowForward,
    this.onOverflowBackward,
    this.onPageTurned,
    this.onSwipeUp,
  });

  @override
  State<PdfView> createState() => _PdfViewState();
}

typedef _SpreadPage = ({PdfDocument document, PdfPage page, bool spill});

class _PdfViewState extends State<PdfView> {
  late final PdfViewModel _viewModel;

  final Map<String, GlobalKey> _pageKeys = {};

  @override
  void initState() {
    super.initState();
    _viewModel = PdfViewModel(
      file: widget.file,
      scoresRepository: context.read(),
      scoreId: widget.scoreId,
      gradual: widget.gradualPageTurns,
      nextPath: widget.nextPath,
      previousPath: widget.previousPath,
      nextScoreId: widget.nextScoreId,
      neighborsSettled: widget.neighborsSettled,
      onOverflowForward: () => widget.onOverflowForward?.call() ?? false,
      onOverflowBackward: () => widget.onOverflowBackward?.call() ?? false,
      onPageTurned: (forward) => widget.onPageTurned?.call(forward),
    );
    widget.controller.attach(_viewModel);
  }

  @override
  void didUpdateWidget(covariant PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detach(_viewModel);
      widget.controller.attach(_viewModel);
    }
    _viewModel.updateGradual(widget.gradualPageTurns);
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
    _viewModel.updateNeighbors(
      next: widget.nextPath,
      previous: widget.previousPath,
      nextScoreId: widget.nextScoreId,
      settled: widget.neighborsSettled,
    );
  }

  @override
  void dispose() {
    widget.controller.detach(_viewModel);
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

        Widget buildPage(_SpreadPage entry) {
          final page = entry.page;
          return AspectRatio(
            aspectRatio: page.width / page.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaQuery(
                  data: mediaQuery.copyWith(
                    devicePixelRatio: max(mediaQuery.devicePixelRatio, 2.0),
                  ),
                  child: PdfPageView(
                    document: entry.document,
                    pageNumber: page.pageNumber,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      strokes: _viewModel.strokesForPage(
                        page.pageNumber,
                        spill: entry.spill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final document = _viewModel.document;
            final spillDocument = _viewModel.spillDocument;
            final pages = <_SpreadPage>[
              if (document != null)
                for (final page in document.pages)
                  (document: document, page: page, spill: false),
              if (spillDocument != null)
                for (final page in spillDocument.pages)
                  (document: spillDocument, page: page, spill: true),
            ];

            (int, double) calcPageCountAndGap(
              int startIndex, {
              bool reverse = false,
            }) {
              int pageCount = 0;
              double totalWidth = 0;
              while (startIndex + pageCount >= 0 &&
                  startIndex + pageCount < pages.length) {
                final newTotalWidth =
                    totalWidth +
                    calcPageWidth(pages[startIndex + pageCount].page);
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

            var pageIndex = _viewModel.currentPageIndex;

            if (_viewModel.needsLastSpreadStart && pages.isNotEmpty) {
              final (lastSpreadCount, _) = calcPageCountAndGap(
                pages.length - 1,
                reverse: true,
              );
              pageIndex = max(0, pages.length - lastSpreadCount);
              _viewModel.updateLastSpreadStart(pageIndex);
            }

            final (pageCount, gap) = calcPageCountAndGap(pageIndex);

            final (nextPageCount, nextGap) = calcPageCountAndGap(
              pageIndex + pageCount,
            );

            final gradual = _viewModel.gradual;
            final handleColor = HSLColor.fromColor(
              Theme.of(context).colorScheme.primary,
            ).withSaturation(1).withLightness(0.5).toColor();

            final (prevPageCount, _) = calcPageCountAndGap(
              pageIndex - 1,
              reverse: !gradual,
            );

            _viewModel.updateForwardPageCount(pageCount);
            _viewModel.updateBackwardPageCount(prevPageCount);

            final failed = _viewModel.loadFailed && !_viewModel.switching;
            final loading =
                (_viewModel.document == null && !failed) ||
                _viewModel.switching;

            final usedPageKeys = <String>{};

            Widget buildKeyedPage(int index) {
              final entry = pages[index];
              final path = entry.spill
                  ? _viewModel.spillPath
                  : _viewModel.documentPath;
              final copy = entry.spill && path == _viewModel.documentPath
                  ? "-spill"
                  : "";
              final id = "$path-${entry.page.pageNumber}$copy";
              usedPageKeys.add(id);
              return KeyedSubtree(
                key: _pageKeys.putIfAbsent(id, GlobalKey.new),
                child: buildPage(entry),
              );
            }

            Widget buildHiddenPage(int index) {
              return Opacity(
                opacity: 0,
                child: Center(child: buildKeyedPage(index)),
              );
            }

            Widget buildHalfPage(int index, {required bool top}) {
              return ClipRect(
                clipper: _SplitClipper(split: _viewModel.split, top: top),
                child: Center(child: buildKeyedPage(index)),
              );
            }

            final half =
                gradual &&
                _viewModel.half &&
                pageCount == 1 &&
                pageIndex + 1 < pages.length;
            final shownPageCount = half ? 2 : pageCount;

            final List<Widget> layers;
            if (loading) {
              layers = const [];
            } else if (gradual) {
              layers = [
                if (pageIndex > 0) buildHiddenPage(pageIndex - 1),
                if (pageIndex + shownPageCount < pages.length)
                  buildHiddenPage(pageIndex + shownPageCount),
                if (half) ...[
                  buildHalfPage(pageIndex, top: false),
                  buildHalfPage(pageIndex + 1, top: true),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: constraints.maxHeight * _viewModel.split - 16,
                    height: 32,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        onVerticalDragUpdate: (details) => _viewModel.moveSplit(
                          details.delta.dy / constraints.maxHeight,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 14.5,
                              height: 3,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: handleColor,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 56,
                              height: 8,
                              decoration: BoxDecoration(
                                color: handleColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: gap,
                    children: [
                      for (var index = 0; index < pageCount; index++)
                        Flexible(child: buildKeyedPage(pageIndex + index)),
                    ],
                  ),
              ];
            } else {
              layers = [
                // back layer
                if (pageCount > 0 && nextPageCount > 0)
                  Row(
                    key: ValueKey(
                      "${pageIndex + pageCount}-${_viewModel.documentPath}",
                    ),
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: nextGap,
                    children: List.generate(nextPageCount, (index) {
                      final page = pages[pageIndex + pageCount + index];
                      return Flexible(
                        child: Opacity(opacity: 0, child: buildPage(page)),
                      );
                    }),
                  ),
                // front layer
                Row(
                  key: ValueKey("$pageIndex-${_viewModel.documentPath}"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: gap,
                  children: List.generate(pageCount, (index) {
                    final page = pages[pageIndex + index];
                    return Flexible(
                      child: Opacity(opacity: 1, child: buildPage(page)),
                    );
                  }),
                ),
              ];
            }
            _pageKeys.removeWhere((id, _) => !usedPageKeys.contains(id));

            return Listener(
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
                onVerticalDragEnd: widget.onSwipeUp == null
                    ? null
                    : (details) {
                        final velocity = details.primaryVelocity;
                        if (velocity != null && velocity < -300) {
                          widget.onSwipeUp!();
                        }
                      },
                onTapUp: (details) {
                  if (details.localPosition.dx < constraints.maxWidth / 2) {
                    _viewModel.prevPage();
                  } else {
                    _viewModel.nextPage();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (loading)
                        const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      if (failed) const _PdfLoadErrorView(),
                      ...layers,
                    ],
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

class _SplitClipper extends CustomClipper<Rect> {
  final double split;
  final bool top;

  const _SplitClipper({required this.split, required this.top});

  @override
  Rect getClip(Size size) {
    final y = size.height * split;
    return top
        ? Rect.fromLTRB(0, 0, size.width, y)
        : Rect.fromLTRB(0, y, size.width, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) =>
      oldClipper.split != split || oldClipper.top != top;
}

class _PdfLoadErrorView extends StatelessWidget {
  const _PdfLoadErrorView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: muted),
            const SizedBox(height: 16),
            Text(
              "This PDF could not be opened.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: muted),
            ),
            const SizedBox(height: 4),
            Text(
              "It may be damaged or password protected.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
