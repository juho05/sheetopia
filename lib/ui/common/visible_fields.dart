/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:sheetopia/ui/common/metadata_field.dart';

/// The optional fields a form or filter dialog currently shows.
class VisibleFields<T extends MetadataField> {
  final Iterable<T> optional;
  final Set<T> _visible = {};

  VisibleFields(this.optional);

  bool contains(T field) => _visible.contains(field);

  Iterable<T> get visible => optional.where(_visible.contains);

  Iterable<T> get hidden => optional.where((f) => !_visible.contains(f));

  bool show(T field) => _visible.add(field);

  void showWhere(bool Function(T field) test) =>
      _visible.addAll(optional.where(test));

  bool remove(T field) => _visible.remove(field);

  void clear() => _visible.clear();
}
