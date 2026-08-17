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

class SourceInputDialog extends StatefulWidget {
  final String title;
  final String submitBtnText;
  final String source;
  final String sourceLink;
  final bool enableClear;
  final Future<Iterable<String>> Function(String filter) getOptions;

  const SourceInputDialog({
    super.key,
    required this.title,
    required this.submitBtnText,
    required this.getOptions,
    this.source = "",
    this.sourceLink = "",
    this.enableClear = false,
  });

  static Future<({String source, String sourceLink})?> show(
    BuildContext context, {
    required String title,
    required String submitBtnText,
    String source = "",
    String sourceLink = "",
    bool enableClear = false,
    required Future<Iterable<String>> Function(String filter) getOptions,
  }) async {
    return showSheetopiaDialog<({String source, String sourceLink})>(
      context: context,
      builder: (context) => SourceInputDialog(
        title: title,
        submitBtnText: submitBtnText,
        source: source,
        sourceLink: sourceLink,
        enableClear: enableClear,
        getOptions: getOptions,
      ),
    );
  }

  @override
  State<SourceInputDialog> createState() => _SourceInputDialogState();
}

class _SourceInputDialogState extends State<SourceInputDialog> {
  late final TextEditingController _sourceController = TextEditingController(
    text: widget.source,
  );
  late final TextEditingController _linkController = TextEditingController(
    text: widget.sourceLink,
  );
  final FocusNode _sourceFocus = FocusNode();
  final FocusNode _linkFocus = FocusNode();

  bool _submitted = false;

  String get _source => _sourceController.text.trim();

  String get _link => _linkController.text.trim();

  bool get _hasSource => _source.isNotEmpty;

  bool get _missingSource => _link.isNotEmpty && !_hasSource;

  bool get _invalidLink => _link.isNotEmpty && _linkUri == null;

  bool get _valid => _hasSource && !_invalidLink;

  Uri? get _linkUri {
    final uri = Uri.tryParse(_link);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != "http" && uri.scheme != "https") return null;
    return uri;
  }

  @override
  void initState() {
    super.initState();
    _sourceController.addListener(_onTextChanged);
    _linkController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _sourceController.removeListener(_onTextChanged);
    _linkController.removeListener(_onTextChanged);
    _sourceController.dispose();
    _linkController.dispose();
    _sourceFocus.dispose();
    _linkFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _submit() {
    if (!_valid || _submitted) return;
    _submitted = true;
    Navigator.pop(context, (
      source: _source,
      sourceLink: _linkUri?.toString() ?? "",
    ));
  }

  Widget? _clearButton(TextEditingController controller) {
    if (controller.text.isEmpty) return null;
    return IconButton(
      icon: const Icon(Icons.clear),
      tooltip: "Clear",
      onPressed: controller.clear,
    );
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
            controller: _sourceController,
            focusNode: _sourceFocus,
            getOptions: widget.getOptions,
            onSubmitted: (value) => _submit(),
            onDialog: true,
            decoration: InputDecoration(
              label: const Text("Source"),
              border: const OutlineInputBorder(),
              errorText: _missingSource ? "Required" : null,
              suffixIcon: _clearButton(_sourceController),
            ),
          ),
          TextField(
            controller: _linkController,
            focusNode: _linkFocus,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onSubmitted: (value) => _submit(),
            onTapOutside: (event) => _linkFocus.unfocus(),
            decoration: InputDecoration(
              label: const Text("Link (optional)"),
              border: const OutlineInputBorder(),
              errorText: _invalidLink ? "Must be an http(s) link" : null,
              suffixIcon: _clearButton(_linkController),
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
              if (widget.enableClear && !_hasSource && _link.isEmpty)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context, (source: "", sourceLink: ""));
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
