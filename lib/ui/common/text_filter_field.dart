/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/metadata_row.dart';

/// A free text filter with suggestions and a clear button.
class TextFilterField extends StatefulWidget {
  final String value;
  final Future<Iterable<String>> Function(String filter) getOptions;
  final void Function(String value) onChanged;
  final String hintText;
  final bool autofocus;

  const TextFilterField({
    super.key,
    required this.value,
    required this.getOptions,
    required this.onChanged,
    this.hintText = "All",
    this.autofocus = false,
  });

  @override
  State<TextFilterField> createState() => _TextFilterFieldState();
}

class _TextFilterFieldState extends State<TextFilterField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(TextFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.isEmpty && _controller.text.trim().isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) => widget.onChanged(value.trim());

  @override
  Widget build(BuildContext context) {
    return AutoCompleteField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      getOptions: widget.getOptions,
      onChanged: _onChanged,
      onSelected: _onChanged,
      decoration: metadataInputDecoration(
        context,
        hintText: widget.hintText,
        suffixIcon: widget.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged("");
                  _focusNode.unfocus();
                },
              )
            : null,
      ),
    );
  }
}
