import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';

class EditTagList extends StatelessWidget {
  final Iterable<Widget> tags;
  final void Function() onAdd;

  const EditTagList({super.key, required this.tags, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 4,
      runSpacing: 4,
      children: tags.followedBy([AddBadge(onTap: onAdd)]).toList(),
    );
  }
}

class AddBadge extends StatelessWidget {
  final void Function()? onTap;

  const AddBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget widget = Padding(
      padding: const EdgeInsets.only(left: 8, right: 12, top: 3, bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4,
        children: [
          const Icon(Icons.add, size: 16),
          Flexible(
            child: Text(
              "Add",
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      widget = InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: widget,
      );
    }
    widget = DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(12),
        padding: const EdgeInsets.all(1),
        dashPattern: [5, 5],
        strokeWidth: 2,
        color: theme.colorScheme.onSurface.withAlpha(160),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: null,
        child: widget,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 5, top: 5),
      child: OptionalTooltip(message: "Add", child: widget),
    );
  }
}
