import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/next_button.dart';
import 'package:sheetopia/ui/edit_score/edit_score_form.dart';
import 'package:sheetopia/ui/edit_score/edit_score_preview.dart';
import 'package:sheetopia/ui/edit_score/edit_score_viewmodel.dart';

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
                  if (viewModel.isImport)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: NextButton(
                          label: viewModel.isImport && !viewModel.hasNext
                              ? "Done"
                              : null,
                          showIcon: viewModel.hasNext,
                          onPressed: () {
                            if (viewModel.hasNext) {
                              viewModel.next();
                            } else {
                              context.pop();
                            }
                          },
                        ),
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
