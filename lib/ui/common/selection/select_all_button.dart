/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class SelectAllButton extends StatelessWidget {
  final int? resultCount;
  final int selectedCount;
  final void Function() onSelectAll;
  final void Function() onClearSelection;

  const SelectAllButton({
    super.key,
    required this.resultCount,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  bool get _allSelected {
    final resultCount = this.resultCount;
    return resultCount != null && selectedCount >= resultCount;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _allSelected ? "Deselect all" : "Select all",
      icon: Icon(_allSelected ? Icons.deselect : Icons.select_all),
      onPressed: _allSelected ? onClearSelection : onSelectAll,
    );
  }
}
