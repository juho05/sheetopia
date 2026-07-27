/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheetopia/ui/common/auto_complete_field.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class AutoCompleteInputDialog extends StatefulWidget {
  final String title;
  final String inputLabel;
  final String submitBtnText;
  final bool enableClear;
  final Future<Iterable<String>> Function(String filter) getOptions;

  const AutoCompleteInputDialog({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.getOptions,
    required this.submitBtnText,
    this.enableClear = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String inputLabel,
    required String submitBtnText,
    bool enableClear = false,
    required Future<Iterable<String>> Function(String filter) getOptions,
  }) async {
    return showSheetopiaDialog<String>(
      context: context,
      builder: (context) => AutoCompleteInputDialog(
        title: title,
        inputLabel: inputLabel,
        getOptions: getOptions,
        submitBtnText: submitBtnText,
        enableClear: enableClear,
      ),
    );
  }

  @override
  State<AutoCompleteInputDialog> createState() =>
      _AutoCompleteInputDialogState();
}

class _AutoCompleteInputDialogState extends State<AutoCompleteInputDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _valid = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    bool newValid = _controller.text.trim().isNotEmpty;
    if (newValid != _valid) {
      setState(() {
        _valid = newValid;
      });
    }
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || _submitted) return;
    _submitted = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _submit,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _submit,
      },
      child: FocusScope(child: _buildDialog(theme)),
    );
  }

  Widget _buildDialog(ThemeData theme) {
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          AutoCompleteField(
            autofocus: true,
            controller: _controller,
            focusNode: _focusNode,
            getOptions: widget.getOptions,
            onSubmitted: (value) => _submit(),
            onDialog: true,
            decoration: InputDecoration(
              label: Text(widget.inputLabel),
              border: const OutlineInputBorder(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              if (widget.enableClear && !_valid)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, "");
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                  child: const Text("Clear"),
                )
              else
                FilledButton(
                  onPressed: _valid ? _submit : null,
                  child: Text(widget.submitBtnText),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
