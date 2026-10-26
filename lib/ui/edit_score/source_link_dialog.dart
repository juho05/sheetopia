/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';

class SourceLinkDialog extends StatefulWidget {
  final String link;

  const SourceLinkDialog({super.key, this.link = ""});

  static Future<String?> show(BuildContext context, {String link = ""}) async {
    return showSheetopiaDialog<String>(
      context: context,
      builder: (context) => SourceLinkDialog(link: link),
    );
  }

  static Uri? parseLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != "http" && uri.scheme != "https") return null;
    return uri;
  }

  @override
  State<SourceLinkDialog> createState() => _SourceLinkDialogState();
}

class _SourceLinkDialogState extends State<SourceLinkDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.link,
  );

  bool _submitted = false;

  String get _link => _controller.text.trim();

  Uri? get _uri => SourceLinkDialog.parseLink(_link);

  bool get _invalid => _link.isNotEmpty && _uri == null;

  bool get _clears => _link.isEmpty && widget.link.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _submit() {
    if (_submitted) return;
    final String result;
    if (_clears) {
      result = "";
    } else if (_uri != null) {
      result = _uri.toString();
    } else {
      return;
    }
    _submitted = true;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false):
            _submit,
        const SingleActivator(
          LogicalKeyboardKey.numpadEnter,
          includeRepeats: false,
        ): _submit,
      },
      child: FocusScope(
        child: SheetopiaDialog(
          maxWidth: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(
                widget.link.isEmpty ? "Add link" : "Edit link",
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (value) => _submit(),
                decoration: InputDecoration(
                  label: const Text("Link"),
                  border: const OutlineInputBorder(),
                  errorText: _invalid ? "Must be an http(s) link" : null,
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: "Clear",
                          onPressed: _controller.clear,
                        ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  if (_clears)
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      child: const Text("Remove"),
                    )
                  else
                    FilledButton(
                      onPressed: _uri == null ? null : _submit,
                      child: const Text("Save"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
