import 'package:flutter/material.dart';
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
                final ids = await context.read<HomeViewModel>().importScores();
                if (!context.mounted || ids.isEmpty) return;
                // TODO replace with navigation to edit page
                if (ids.length == 1) {
                  Toast.show(context, "Successfully imported score!");
                } else {
                  Toast.show(
                    context,
                    "Successfully imported ${ids.length} scores!",
                  );
                }
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
