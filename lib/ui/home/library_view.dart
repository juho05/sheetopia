import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LibraryViewModel(repo: context.read()),
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            Consumer<LibraryViewModel>(
              builder: (context, viewModel, _) {
                return SliverList.builder(
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(viewModel.scores[index].title),
                      onTap: () {
                        context.go("/scores/${viewModel.scores[index].id}");
                      },
                      trailing: IconButton(
                        onPressed: () {
                          context.go(
                            "/scores/${viewModel.scores[index].id}/edit",
                          );
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    );
                  },
                  itemCount: viewModel.scores.length,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
