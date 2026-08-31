/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

class SelectionGestures<T> {
  final T item;
  final bool selecting;
  final void Function(T item)? onToggle;
  final void Function(T item)? onSelectionStart;
  final void Function(T item)? onRangeSelect;
  final void Function()? onActivate;

  const SelectionGestures({
    required this.item,
    this.selecting = false,
    this.onToggle,
    this.onSelectionStart,
    this.onRangeSelect,
    this.onActivate,
  });

  static bool get _isApple => Platform.isIOS || Platform.isMacOS;

  static bool get _selectModifierPressed => _isApple
      ? HardwareKeyboard.instance.isMetaPressed
      : HardwareKeyboard.instance.isControlPressed;

  void Function()? get onTap {
    if (!selecting && onActivate == null && onSelectionStart == null) {
      return null;
    }
    return () {
      if (onRangeSelect != null && HardwareKeyboard.instance.isShiftPressed) {
        onRangeSelect!(item);
        return;
      }
      if (selecting) {
        onToggle?.call(item);
        return;
      }
      if (onSelectionStart != null && _selectModifierPressed) {
        onSelectionStart!(item);
        return;
      }
      onActivate?.call();
    };
  }

  void Function()? get onLongPress => !selecting && onSelectionStart != null
      ? () {
          HapticFeedback.mediumImpact();
          onSelectionStart!(item);
        }
      : null;
}

class RangeSelectionAnchor {
  String? _anchorId;

  set anchor(String? id) => _anchorId = id;

  void clear() => _anchorId = null;

  List<String>? rangeTo(List<String> orderedIds, String targetId) {
    final anchorId = _anchorId;
    if (anchorId == null) return null;
    final anchor = orderedIds.indexOf(anchorId);
    final target = orderedIds.indexOf(targetId);
    if (anchor < 0 || target < 0) return null;
    return [
      for (var i = min(anchor, target); i <= max(anchor, target); i++)
        orderedIds[i],
    ];
  }
}
