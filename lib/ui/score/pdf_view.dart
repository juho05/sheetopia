import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            // TODO calculate page count and gap size
            return Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    min(_viewModel.document?.pages.length ?? 0, 1),
                    (index) {
                      final page = _viewModel.document!.pages[index];
                      return Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                constraints.maxHeight *
                                (page.width / page.height),
                          ),
                          child: PdfPageView(
                            document: _viewModel.document!,
                            pageNumber: index + 1,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
