import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/ui/score/pdf_viewmodel.dart';

class PdfView extends StatefulWidget {
  final File file;

  const PdfView({super.key, required this.file});

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  late final PdfViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfViewModel(file: widget.file);
  }

  @override
  void didUpdateWidget(covariant PdfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file != oldWidget.file) {
      _viewModel.updateFile(widget.file);
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

            void nextPage() {
              _viewModel.nextPage(pageCount);
            }

            void prevPage() {
              final (count, _) = calcPageCountAndGap(
                _viewModel.currentPageIndex - 1,
                reverse: true,
              );
              _viewModel.prevPage(count);
            }

            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.arrowUp): prevPage,
                const SingleActivator(LogicalKeyboardKey.arrowDown): nextPage,
                const SingleActivator(LogicalKeyboardKey.arrowLeft): prevPage,
                const SingleActivator(LogicalKeyboardKey.arrowRight): nextPage,
                const SingleActivator(LogicalKeyboardKey.pageUp): prevPage,
                const SingleActivator(LogicalKeyboardKey.pageDown): nextPage,
                const SingleActivator(LogicalKeyboardKey.space): nextPage,
                const SingleActivator(LogicalKeyboardKey.enter): nextPage,
                const SingleActivator(LogicalKeyboardKey.backspace): prevPage,
              },
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent &&
                      event.kind == PointerDeviceKind.mouse) {
                    if (event.scrollDelta.dy > 0) {
                      nextPage();
                    } else {
                      prevPage();
                    }
                  }
                },
                child: GestureDetector(
                  onTapUp: (details) {
                    if (details.localPosition.dx < constraints.maxWidth / 2) {
                      prevPage();
                    } else {
                      nextPage();
                    }
                  },
                  child: FocusScope(
                    autofocus: true,
                    child: Material(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // back layer
                          if (pageCount > 0 && nextPageCount > 0)
                            Row(
                              key: ValueKey(
                                "${_viewModel.currentPageIndex + pageCount}-${widget.file.path}",
                              ),
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: nextGap,
                              children: List.generate(nextPageCount, (index) {
                                final page =
                                    pages[_viewModel.currentPageIndex +
                                        pageCount +
                                        index];
                                return Flexible(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          constraints.maxHeight *
                                          (page.width / page.height),
                                    ),
                                    child: MediaQuery(
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
                                  ),
                                );
                              }),
                            ),
                          const Material(),
                          // front layer
                          Row(
                            key: ValueKey(
                              "${_viewModel.currentPageIndex}-${widget.file.path}",
                            ),
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: gap,
                            children: List.generate(pageCount, (index) {
                              final page =
                                  pages[_viewModel.currentPageIndex + index];
                              return Flexible(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        constraints.maxHeight *
                                        (page.width / page.height),
                                  ),
                                  child: MediaQuery(
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
