/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/heading.dart';
import 'package:sheetopia/ui/common/surface.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> trailing;
  final EdgeInsets padding;
  final Widget child;

  final void Function()? onTap;

  const SectionCard({
    super.key,
    this.title,
    this.trailing = const [],
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    required this.child,
  });

  static const double _buttonInset = 4;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final theme = Theme.of(context);
    final buttonHeader = title != null && trailing.isNotEmpty;
    return Material(
      color: Surface.raisedOf(context),
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: buttonHeader
              ? const EdgeInsets.only(top: _buttonInset)
              : padding,
          child: Surface.tile(
            context,
            child: title == null
                ? child
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: buttonHeader ? _buttonInset : 12,
                    children: [
                      Padding(
                        padding: buttonHeader
                            ? EdgeInsets.only(
                                left: padding.left,
                                right: _buttonInset,
                              )
                            : EdgeInsets.zero,
                        child: Row(
                          spacing: 12,
                          children: [
                            Expanded(child: Heading(text: title)),
                            ...trailing,
                            if (onTap != null)
                              Icon(
                                Symbols.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: buttonHeader
                            ? EdgeInsets.fromLTRB(
                                padding.left,
                                0,
                                padding.right,
                                padding.bottom,
                              )
                            : EdgeInsets.zero,
                        child: child,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
