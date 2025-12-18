import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

class EditScorePreview extends StatelessWidget {
  final Score score;

  const EditScorePreview({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    if (score.file == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Stack(
      children: [
        switch (score.fileType) {
          FileType.pdf => PdfViewer.file(
            score.file!.path,
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
