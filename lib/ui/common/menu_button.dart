import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ContextMenuOption {
  final IconData? icon;
  final String title;
  final void Function()? onSelected;

  ContextMenuOption({this.icon, required this.title, required this.onSelected});
}

class MenuButton extends StatelessWidget {
  final Iterable<ContextMenuOption> options;
  final Icon icon;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  const MenuButton({
    super.key,
    this.icon = const Icon(Icons.more_vert),
    required this.options,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final compact =
        kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return PopupMenuButton<ContextMenuOption>(
      icon: icon,
      tooltip: tooltip,
      padding: padding,
      onSelected: (option) {
        if (option.onSelected == null) return;
        option.onSelected!();
      },
      menuPadding: const EdgeInsets.all(0),
      itemBuilder: (context) => options
          .map(
            (o) => PopupMenuItem<ContextMenuOption>(
              value: o,
              height: compact ? 40 : kMinInteractiveDimension,
              child: ListTile(
                minVerticalPadding: compact ? 0 : null,
                minTileHeight: compact ? 40 : null,
                mouseCursor: SystemMouseCursors.click,
                leading: o.icon != null ? Icon(o.icon) : null,
                title: Text(o.title),
              ),
            ),
          )
          .toList(),
    );
  }
}
