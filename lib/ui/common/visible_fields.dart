/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:sheetopia/ui/common/metadata_field.dart';

class VisibleFields<T extends MetadataField> {
  final Iterable<T> optional;
  final bool Function(T field) isFilled;
  final Set<T> _visible = {};

  VisibleFields(this.optional, {required this.isFilled});

  bool isVisible(T field) =>
      !optional.contains(field) || _visible.contains(field) || isFilled(field);

  Iterable<T> get hidden => optional.where((f) => !isVisible(f));

  bool show(T field) => _visible.add(field);

  void showFilled() => _visible.addAll(optional.where(isFilled));

  bool remove(T field) => _visible.remove(field);

  void clear() => _visible.clear();
}
