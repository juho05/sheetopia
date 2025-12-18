import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form.dart';
import 'package:sheetopia/ui/edit_score/edit_score_preview.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/nextdonedelete_button.dart';

class EditScoreDesktop extends StatelessWidget {
  const EditScoreDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditScoreViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.score == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Expanded(child: EditScoreForm()),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: NextDoneDeleteButton(viewModel: viewModel),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(),
            Expanded(child: EditScorePreview(score: viewModel.score!)),
          ],
        );
      },
    );
  }
}
