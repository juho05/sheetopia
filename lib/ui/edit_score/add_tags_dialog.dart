import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/tag_list.dart';
import 'package:sheetopia/ui/edit_score/add_tags_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/create_tag_dialog.dart';

class AddTagsDialog extends StatelessWidget {
  final AddTagsViewModel viewModel;

  const AddTagsDialog({super.key, required this.viewModel});

  static Future<List<Tag>?> show(
    BuildContext context,
    Set<Tag> alreadySelected,
  ) async {
    final viewModel = AddTagsViewModel(
      scoreTags: alreadySelected,
      repo: context.read(),
    );
    return showAdaptiveDialog<List<Tag>>(
      context: context,
      builder: (context) => AddTagsDialog(viewModel: viewModel),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 560),
      insetPadding: const EdgeInsets.all(8),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(
                  "Add tags",
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
                SearchInput(
                  label: "Search or create",
                  debounce: const Duration(milliseconds: 50),
                  onSearch: (query) {
                    viewModel.filter(query);
                  },
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          max(
                            1,
                            ((viewModel.currentFilter.isNotEmpty ? 1 : 0) +
                                viewModel.results.length),
                          ) *
                          _TagListItem.verticalExtent,
                    ),
                    child:
                        viewModel.currentFilter.isNotEmpty ||
                            viewModel.results.isNotEmpty
                        ? Material(
                            type: MaterialType.transparency,
                            child: ListView.builder(
                              itemExtent: _TagListItem.verticalExtent,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  viewModel.results.length +
                                  (viewModel.currentFilter.isNotEmpty ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0 &&
                                    viewModel.currentFilter.isNotEmpty) {
                                  final filter = viewModel.currentFilter;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SizedBox(
                                      height: _TagListItem.verticalExtent - 8,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(5),
                                        onTap: () async {
                                          final tag =
                                              await CreateTagDialog.show(
                                                context,
                                                filter,
                                              );
                                          if (!context.mounted || tag == null) {
                                            return;
                                          }
                                          viewModel.createdTag(tag);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            border: BoxBorder.all(
                                              color: theme.colorScheme.primary,
                                              width: 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text("Create tag '$filter'…"),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                if (viewModel.currentFilter.isNotEmpty) {
                                  index--;
                                }
                                final t = viewModel.results[index];
                                return _TagListItem(
                                  tag: t,
                                  selected: viewModel.selected.contains(t),
                                  onSelect: () => viewModel.select(t),
                                  onDeselect: () => viewModel.deselect(t),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Text(
                              "Use the search bar to create a new tag.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${viewModel.selected.length} tags selected"),
                    if (viewModel.selected.isEmpty)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        child: const Text("Cancel"),
                      ),
                    if (viewModel.selected.isNotEmpty)
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, viewModel.selected.toList());
                        },
                        child: const Text("Add"),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TagListItem extends StatelessWidget {
  static const double verticalExtent = 42;

  final Tag tag;
  final bool selected;

  final void Function() onSelect;
  final void Function() onDeselect;

  const _TagListItem({
    required this.tag,
    required this.selected,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: verticalExtent,
      child: InkWell(
        onTap: selected ? onDeselect : onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            spacing: 12,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(selected ? Icons.check_box : Icons.check_box_outline_blank),
              Flexible(
                child: TagWidget(name: tag.name, color: tag.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
