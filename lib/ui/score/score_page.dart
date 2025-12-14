import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/score/pdf_view.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';

class ScorePage extends StatelessWidget {
  final String scoreId;

  const ScorePage({super.key, required this.scoreId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ScoreViewModel(repo: context.read(), scoreId: scoreId),
      builder: (context, _) {
        final theme = Theme.of(context);
        final background = theme.colorScheme.surface;
        final foreground = theme.colorScheme.onSurface;
        final darkTheme = theme.brightness == Brightness.dark;
        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Consumer<ScoreViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.file == null) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }
                    return switch (viewModel.fileType!) {
                      FileType.pdf => PdfView(file: viewModel.file!),
                    };
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Material(
                    borderRadius: BorderRadius.circular(999999),
                    color: darkTheme
                        ? background.withAlpha(100)
                        : foreground.withAlpha(100),
                    child: const BackButton(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
