/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// only returns 0 for identical names, so names differing in case stay distinct in sorted sets
int compareNames(String a, String b) {
  final byLower = a.toLowerCase().compareTo(b.toLowerCase());
  return byLower != 0 ? byLower : a.compareTo(b);
}
