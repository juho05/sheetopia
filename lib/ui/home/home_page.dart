import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/home/home_viewmodel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(),
      builder: (context, _) {
        return Consumer<HomeViewModel>(
          builder: (context, viewModel, _) {
            return Scaffold(
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (viewModel.pdf == null) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }
                    return GestureDetector(
                      onTapUp: (details) {
                        if (details.localPosition.dx <
                            constraints.maxWidth / 2) {
                          viewModel.prevPage();
                        } else {
                          viewModel.nextPage();
                        }
                      },
                      child: Material(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth:
                                  constraints.maxHeight *
                                  (viewModel.currentPage.width /
                                      viewModel.currentPage.height),
                            ),
                            child: PdfPageView(
                              document: viewModel.pdf!,
                              pageNumber: viewModel.currentPageNumber,
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
      },
    );
  }
}
