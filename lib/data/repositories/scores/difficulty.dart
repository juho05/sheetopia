/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

enum Difficulty {
  veryEasy(1, "Very easy"),
  easy(2, "Easy"),
  medium(3, "Medium"),
  hard(4, "Hard"),
  veryHard(5, "Very hard");

  final int level;
  final String label;

  const Difficulty(this.level, this.label);

  static Difficulty? fromLevel(int? level) {
    for (final d in values) {
      if (d.level == level) return d;
    }
    return null;
  }
}
