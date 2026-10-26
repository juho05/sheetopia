/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/common/source_value.dart';

void main() {
  test("clearing the name keeps the link unsaved until it is retyped", () {
    final state = SourceState()..load("IMSLP", "https://imslp.org");

    expect(state.updateName(""), isTrue);
    expect(state.name, isNull);
    expect(state.link, "https://imslp.org");
    expect(state.savedLink, "");

    expect(state.updateName("IMSLP"), isTrue);
    expect(state.savedLink, "https://imslp.org");
  });

  test("syncing an empty name keeps the remembered link", () {
    final state = SourceState()..load("IMSLP", "https://imslp.org");
    state.updateName("");

    state.sync(null, null);
    state.updateName("Henle");

    expect(state.savedLink, "https://imslp.org");
  });

  test("syncing a new name replaces the link", () {
    final state = SourceState()..load("IMSLP", "https://imslp.org");
    state.updateName("");

    state.sync("Henle", "https://henle.de");

    expect(state.name, "Henle");
    expect(state.link, "https://henle.de");
  });

  test("setting an empty name drops the link", () {
    final state = SourceState()..load("IMSLP", "https://imslp.org");

    state.set("", "");
    state.updateName("IMSLP");

    expect(state.link, isNull);
  });
}
