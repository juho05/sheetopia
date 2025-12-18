import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScorePreview extends StatefulWidget {
  final Score score;

  const EditScorePreview({super.key, required this.score});

  @override
  State<EditScorePreview> createState() => _EditScorePreviewState();
}

class _EditScorePreviewState extends State<EditScorePreview> {
  PdfDocumentRefFile? pdfRef;

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
            params: const PdfViewerParams(
              scrollPhysics: ClampingScrollPhysics(),
            ),
          ),
        },
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
              onPressed: () => context.read<EditScoreViewModel>().changeFile(),
              icon: const Icon(Icons.edit),
              label: const Text("Change"),
            ),
          ),
        ),
      ],
    );
  }
}
