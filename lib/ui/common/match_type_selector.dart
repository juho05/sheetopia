/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/filter_match_type.dart';

class MatchTypeSelector extends StatelessWidget {
  final FilterMatchType value;
  final ValueChanged<FilterMatchType> onChanged;

  const MatchTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static String _label(FilterMatchType type) {
    switch (type) {
      case FilterMatchType.any:
        return "Any";
      case FilterMatchType.all:
        return "All";
      case FilterMatchType.exact:
        return "Exact";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<FilterMatchType>(
      initialValue: value,
      tooltip: "Match type",
      onSelected: onChanged,
      itemBuilder: (context) => FilterMatchType.values
          .map(
            (t) => PopupMenuItem<FilterMatchType>(
              value: t,
              child: Text(_label(t)),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(_label(value), style: theme.textTheme.labelLarge),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}