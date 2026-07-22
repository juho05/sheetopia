/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class SetlistNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialName;

  const SetlistNameDialog._({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String initialName = "",
  }) {
    return showSheetopiaDialog<String>(
      context: context,
      builder: (context) => SetlistNameDialog._(
        title: title,
        confirmLabel: confirmLabel,
        initialName: initialName,
      ),
    );
  }

  @override
  State<SetlistNameDialog> createState() => _SetlistNameDialogState();
}

class _SetlistNameDialogState extends State<SetlistNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            onTapOutside: (event) => _focus.unfocus(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Name",
            ),
          ),
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
                child: Text(widget.confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
