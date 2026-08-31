/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/ui/common/rounded_tile_icon.dart';

class SelectableTileIcon extends StatelessWidget {
  final IconData icon;
  final bool selecting;
  final bool selected;

  const SelectableTileIcon({
    super.key,
    required this.icon,
    this.selecting = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!selecting) return RoundedTileIcon(icon: icon);
    return RoundedTileIcon(
      icon: selected ? Symbols.check : Symbols.radio_button_unchecked,
      color: selected ? theme.colorScheme.primary : null,
      iconColor: selected ? theme.colorScheme.onPrimary : null,
    );
  }
}
