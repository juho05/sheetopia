import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/ui/home/library_viewmodel.dart';
import 'package:sheetopia/ui/home/score_grid_cell.dart';
import 'package:sheetopia/ui/home/sliver_score_grid.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = LibraryViewModel(repo: context.read());
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _loadInitialPages().then((value) {
        _scrollController.addListener(_onScroll);
      });
    });
  }

  Future<void> _loadInitialPages() async {
    while (_isBottom && _viewModel.hasNextPage) {
      await _viewModel.loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _viewModel.loadNextPage();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll - 3 * ScoreGridCell.height);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return SliverScoreGrid(scores: _viewModel.scores);
          },
        ),
      ],
    );
  }
}
