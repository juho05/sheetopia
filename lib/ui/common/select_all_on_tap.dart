/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';

/// Selects the whole text when a tap focuses the field.
/// Pass `onTap` to the text field built by [builder].
class SelectAllOnTap extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget Function(void Function() onTap) builder;

  const SelectAllOnTap({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.builder,
  });

  @override
  State<SelectAllOnTap> createState() => _SelectAllOnTapState();
}

class _SelectAllOnTapState extends State<SelectAllOnTap> {
  bool _focusedAtPointerDown = false;

  void _onTap() {
    if (_focusedAtPointerDown) return;
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _focusedAtPointerDown = widget.focusNode.hasFocus,
      child: widget.builder(_onTap),
    );
  }
}
