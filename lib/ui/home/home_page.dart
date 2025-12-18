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
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(scoresRepo: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Library")),
          body: const SafeArea(child: LibraryView()),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
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
            tooltip: "Import score",
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
