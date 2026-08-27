/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  static const double collapseWidth = 500;

  final bool active;
  final bool collapsed;
  final String label;
  final void Function() onPressed;

  const FilterButton({
    super.key,
    required this.active,
    required this.onPressed,
    this.collapsed = false,
    this.label = "Filter",
  });

  @override
  Widget build(BuildContext context) {
    final icon = active
        ? const Icon(Icons.filter_alt)
        : const Icon(Icons.filter_alt_outlined);
    if (collapsed) {
      return IconButton(icon: icon, onPressed: onPressed);
    }
    if (active) {
      return FilledButton.icon(
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      icon: icon,
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
