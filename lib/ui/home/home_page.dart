import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/home/home_viewmodel.dart';
import 'package:sheetopia/ui/home/library_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = Color.fromARGB(
      255,
      theme.brightness == Brightness.light ? 227 : 46,
      theme.brightness == Brightness.light ? 220 : 43,
      theme.brightness == Brightness.light ? 228 : 48,
    );
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(scoresRepo: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Library")),
          body: const SafeArea(child: LibraryView()),
          floatingActionButton: Consumer<HomeViewModel>(
            builder: (context, viewModel, _) {
              return FloatingActionButton(
                onPressed: viewModel.importing
                    ? null
                    : () async {
                        try {
                          final firstScoreId = await context
                              .read<HomeViewModel>()
                              .importScores();
                          if (!context.mounted || firstScoreId == null) return;
                          context.go("/scores/$firstScoreId/edit");
                        } catch (e, st) {
                          Toast.exception(
                            context,
                            e,
                            st: st,
                            errorMsg: "Failed to import scores!",
                          );
                        }
                      },
                backgroundColor: viewModel.importing ? disabledColor : null,
                tooltip: "Import score",
                child: viewModel.importing
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator.adaptive(),
                      )
                    : const Icon(Icons.add),
              );
            },
          ),
        );
      },
    );
  }
}
