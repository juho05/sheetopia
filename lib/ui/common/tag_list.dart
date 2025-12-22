import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';

typedef TagListItem = ({String id, String name, Color? color});

class TagList extends StatelessWidget {
  final Iterable<TagListItem> tags;
  final String? emptyText;
  final void Function()? onAdd;
  final void Function(String id)? onRemove;

  const TagList({
    super.key,
    required this.tags,
    this.emptyText,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty && emptyText != null && onAdd == null) {
      return Text(emptyText!);
    }
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 4,
      runSpacing: 4,
      children: tags
          .map<Widget>(
            (e) => TagWidget(
              name: e.name,
              color: e.color,
              onRemove: onRemove != null
                  ? () {
                      onRemove!(e.id);
                    }
                  : null,
            ),
          )
          .followedBy(
            onAdd != null
                ? [
                    Padding(
                      padding: onRemove != null
                          ? const EdgeInsets.only(left: 5, top: 5)
                          : const EdgeInsets.all(0),
                      child: TagWidget(
                        name: "Add",
                        icon: Icons.add,
                        onTap: onAdd,
                        borderColor: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ]
                : [],
          )
          .toList(),
    );
  }
}

class TagWidget extends StatelessWidget {
  final String name;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;
  final void Function()? onTap;
  final void Function()? onRemove;

  const TagWidget({
    super.key,
    required this.name,
    this.color,
    this.borderColor,
    this.onTap,
    this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color != null
        ? color!.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
        : null;
    Widget widget = Material(
      borderRadius: BorderRadius.circular(12),
      color: color != null || borderColor != null
          ? color
          : theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            left: borderColor != null ? 8 : 9,
            right: (icon != null ? 12 : 8) + (borderColor != null ? 0 : 1),
            top: borderColor != null ? 3 : 4,
            bottom: borderColor != null ? 3 : 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4,
            children: [
              if (icon != null) Icon(icon, size: 16),
              Flexible(
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: foregroundColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (borderColor != null) {
      widget = DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(12),
          padding: const EdgeInsets.all(1),
          dashPattern: [5, 5],
          strokeWidth: 2,
          color: borderColor!,
        ),
        child: widget,
      );
    }

    if (onRemove != null) {
      widget = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5),
            child: widget,
          ),
          SizedBox.square(
            dimension: 15,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove),
              iconSize: 11,
              color: theme.colorScheme.onErrorContainer,
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
              ),
              padding: const EdgeInsets.all(0),
            ),
          ),
        ],
      );
    }

    return OptionalTooltip(message: name, child: widget);
  }
}
