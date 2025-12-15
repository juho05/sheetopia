import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/score/pdf_view.dart';
import 'package:sheetopia/ui/score/score_viewmodel.dart';

class ScorePage extends StatefulWidget {
  final String scoreId;

  const ScorePage({super.key, required this.scoreId});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  @override
  void dispose() {
    if (FullScreen.isFullScreen) {
      FullScreen.setFullScreen(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ScoreViewModel(repo: context.read(), scoreId: widget.scoreId),
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Consumer<ScoreViewModel>(
              builder: (context, viewModel, _) {
                return MouseRegion(
                  cursor: !viewModel.isFullScreen || viewModel.overlayVisible
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.none,
                  child: Listener(
                    onPointerHover: (event) => viewModel.showOverlay(),
                    onPointerMove: (event) => viewModel.showOverlay(),
                    onPointerDown: (event) => viewModel.showOverlay(),
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.escape):
                            viewModel.exitFullScreen,
                        const SingleActivator(LogicalKeyboardKey.keyF):
                            viewModel.toggleFullScreen,
                        const SingleActivator(LogicalKeyboardKey.f11):
                            viewModel.toggleFullScreen,
                      },
                      child: FocusScope(
                        autofocus: true,
                        child: Stack(
                          children: [
                            if (viewModel.file == null)
                              const Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            if (viewModel.file != null)
                              switch (viewModel.fileType!) {
                                FileType.pdf => PdfView(file: viewModel.file!),
                              },
                            if (!viewModel.isFullScreen)
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: SizedBox.square(
                                  dimension: 32,
                                  child: IconButton.filled(
                                    color: Colors.white,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(
                                        Colors.black.withAlpha(100),
                                      ),
                                    ),
                                    icon: const BackButtonIcon(),
                                    iconSize: 20,
                                    padding: const EdgeInsets.all(0),
                                    onPressed: () {
                                      context.pop();
                                    },
                                  ),
                                ),
                              ),
                            if (Platform.isWindows ||
                                Platform.isMacOS ||
                                Platform.isLinux)
                              AnimatedOpacity(
                                opacity: viewModel.overlayVisible ? 1 : 0,
                                duration: const Duration(milliseconds: 50),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: IconButton.filled(
                                      onPressed: () {
                                        viewModel.toggleFullScreen();
                                      },
                                      color: Colors.white,
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                              Colors.black.withAlpha(100),
                                            ),
                                      ),
                                      iconSize: 26,
                                      padding: const EdgeInsets.all(10),
                                      icon: viewModel.isFullScreen
                                          ? const Icon(Icons.fullscreen_exit)
                                          : const Icon(Icons.fullscreen),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
