/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/ui/common/metadata_field.dart';

enum ExerciseField implements MetadataField {
  category("Category", Symbols.category),
  instrument("Instrument", Symbols.piano),
  difficulty("Difficulty", Symbols.signal_cellular_alt),
  source("Source", Symbols.link),
  description("Description", Symbols.notes),
  tags("Tags", Symbols.label);

  @override
  final String label;
  @override
  final IconData icon;

  const ExerciseField(this.label, this.icon);

  /// only shown in the edit form when they have a value or were added
  static const formOptional = [difficulty, source];

  /// only shown in the exercise filter dialog when active or added
  static const exerciseFilterOptional = [difficulty, source];

  /// only shown in the routine filter dialog when active or added
  static const routineFilterOptional = [source];
}
