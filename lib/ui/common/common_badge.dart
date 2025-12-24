import 'package:flutter/material.dart';

import 'optional_tooltip.dart';

class CommonBadge extends StatelessWidget {
  final String name;
  final Color? color;
  final void Function()? onTap;
  final void Function()? onRemove;

  const CommonBadge({
    super.key,
    required this.name,
    this.color,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color != null
        ? color!.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white
        : null;
    Widget widget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 9),
      child: Text(
        name,
        style: theme.textTheme.bodySmall!.copyWith(color: foregroundColor),
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (onTap != null) {
      widget = InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: widget,
      );
    }
    widget = Material(
      borderRadius: BorderRadius.circular(12),
      color: color ?? theme.colorScheme.surfaceContainerHigh,
      child: widget,
    );

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
