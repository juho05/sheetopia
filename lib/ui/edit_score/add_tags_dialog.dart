import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/confirmation.dart';
import 'package:sheetopia/ui/common/search_input.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/edit_score/add_tags_viewmodel.dart';
import 'package:sheetopia/ui/edit_score/edit_tag_dialog.dart';

class AddTagsDialog extends StatelessWidget {
  final AddTagsViewModel viewModel;
  final void Function()? reloadTagsCallback;
  final String title;
  final String addBtnText;
  final bool enableTagEdits;

  const AddTagsDialog._({
    required this.viewModel,
    required this.enableTagEdits,
    this.title = "Add tags",
    this.addBtnText = "Add",
    this.reloadTagsCallback,
  });

  static Future<List<Tag>?> show(
    BuildContext context, {
    required bool enableTagEdits,
    Set<Tag> alreadySelected = const {},
    void Function()? reloadTags,
    String title = "Add tags",
    String addBtnText = "Add",
  }) async {
    final viewModel = AddTagsViewModel(
      scoreTags: alreadySelected,
      repo: context.read(),
    );
    return showSheetopiaDialog<List<Tag>>(
      context: context,
      builder: (context) => AddTagsDialog._(
        viewModel: viewModel,
        reloadTagsCallback: reloadTags,
        enableTagEdits: enableTagEdits,
        title: title,
        addBtnText: addBtnText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetopiaDialog(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, child) {
          final showCreate =
              enableTagEdits && viewModel.currentFilter.isNotEmpty;
          return PopScope(
            canPop: !viewModel.manageTagsMode || !enableTagEdits,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && viewModel.manageTagsMode) {
                viewModel.exitManageTagsMode();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Stack(
                  alignment: AlignmentGeometry.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 64),
                      child: Text(
                        viewModel.manageTagsMode ? "Manage tags" : title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (viewModel.manageTagsMode)
                      Align(
                        alignment: AlignmentGeometry.topLeft,
                        child: IconButton(
                          onPressed: () => viewModel.exitManageTagsMode(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      ),
                    if (!viewModel.manageTagsMode && enableTagEdits)
                      Align(
                        alignment: AlignmentGeometry.topRight,
                        child: IconButton(
                          onPressed: () => viewModel.enterManageTagsMode(),
                          icon: const Icon(Icons.edit),
                        ),
                      ),
                  ],
                ),
                SearchInput(
                  label: enableTagEdits ? "Search or create" : "Search",
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
                            ((showCreate ? 1 : 0) + viewModel.results.length),
                          ) *
                          _TagListItem.verticalExtent,
                    ),
                    child: showCreate || viewModel.results.isNotEmpty
                        ? Material(
                            type: MaterialType.transparency,
                            child: ListView.builder(
                              itemExtent: _TagListItem.verticalExtent,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  viewModel.results.length +
                                  (showCreate ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0 && showCreate) {
                                  final filter = viewModel.currentFilter;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: SizedBox(
                                      height: _TagListItem.verticalExtent - 8,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(5),
                                        onTap: () async {
                                          final tag =
                                              await EditTagDialog.showCreate(
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
                                if (showCreate) {
                                  index--;
                                }
                                final t = viewModel.results[index];
                                if (viewModel.manageTagsMode) {
                                  return _ManageTagListItem(
                                    tag: t,
                                    onEdit: () async {
                                      final edited =
                                          await EditTagDialog.showEdit(
                                            context,
                                            t,
                                          );
                                      if (!edited) return;
                                      await viewModel.editedTag();
                                      if (viewModel.scoreTags.contains(t)) {
                                        reloadTagsCallback?.call();
                                      }
                                    },
                                    onDelete: () async {
                                      final confirmation =
                                          await ConfirmationDialog.showYesNo(
                                            context,
                                            message: "Delete '${t.name}'?",
                                          );
                                      if (confirmation != true) return;
                                      await viewModel.deleteTag(t);
                                    },
                                  );
                                }
                                return _TagListItem(
                                  tag: t,
                                  selected: viewModel.selected.contains(t),
                                  onSelect: () => viewModel.select(t),
                                  onDeselect: () => viewModel.deselect(t),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              enableTagEdits
                                  ? "Use the search bar to create a new tag."
                                  : "No tags found.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
                if (!viewModel.manageTagsMode) const Divider(height: 1),
                if (!viewModel.manageTagsMode)
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
                          child: Text(addBtnText),
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
              Flexible(child: TagBadge(tag: tag)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageTagListItem extends StatelessWidget {
  static const double verticalExtent = 42;

  final Tag tag;

  final void Function() onEdit;
  final void Function() onDelete;

  const _ManageTagListItem({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: verticalExtent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: TagBadge(tag: tag)),
            Row(
              children: [
                IconButton(
                  onPressed: onDelete,
                  color: theme.colorScheme.error,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
