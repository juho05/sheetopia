/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';

final class InstrExpression extends Expression<int> {
  final Expression<String> string;
  final Expression<String> substring;

  InstrExpression({required this.string, required this.substring});

  @override
  Precedence get precedence => Precedence.primary;

  @override
  void writeInto(GenerationContext context) {
    context.buffer.write("instr(");
    string.writeInto(context);
    context.buffer.write(",");
    substring.writeInto(context);
    context.buffer.write(")");
  }
}
