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

enum ScoreField implements MetadataField {
  composer("Composer", Symbols.artist),
  arranger("Arranger", Symbols.queue_music),
  partOf("Part of", Symbols.stacks),
  source("Source", Symbols.book_2),
  difficulty("Difficulty", Symbols.signal_cellular_alt),
  instruments("Instruments", Symbols.piano),
  genres("Genres", Symbols.genres),
  tags("Tags", Symbols.label),
  notes("Notes", Symbols.notes);

  @override
  final String label;
  @override
  final IconData icon;

  const ScoreField(this.label, this.icon);

  /// only shown in the edit form when they have a value or were added
  static const formOptional = [
    arranger,
    partOf,
    difficulty,
    source,
    genres,
    notes,
  ];

  /// only shown in the filter dialog when they are active or were added
  static const filterOptional = [arranger, partOf, difficulty, source, genres];
}
