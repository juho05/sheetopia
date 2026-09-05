/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheetopia/ui/common/common_badge.dart';

class AutoCompleteField extends StatefulWidget {
  final Future<Iterable<String>> Function(String filter) getOptions;
  final void Function(String option)? onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget Function(
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
  )?
  fieldBuilder;

  const AutoCompleteField({
    super.key,
    required this.getOptions,
    this.onSelected,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.fieldBuilder,
  });

  @override
  State<AutoCompleteField> createState() => _AutoCompleteFieldState();
}

class _AutoCompleteFieldState extends State<AutoCompleteField> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;
  final FocusNode _groupNode = FocusNode();
  final FocusNode _optionsNode = FocusNode();

  List<String> _options = const [];
  String? _filter;
  int _request = 0;

  late final _FocusFirstOptionAction _focusFirstOptionAction =
      _FocusFirstOptionAction(
        onInvoke: (intent) {
          _focusFirstOption();
          return null;
        },
        isEnabledCallback: () => _showOptions,
      );

  TextEditingController get _controller =>
      widget.controller ?? _ownedController!;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _showOptions => _options.isNotEmpty && _groupNode.hasFocus;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _ownedController = TextEditingController();
    if (widget.focusNode == null) _ownedFocusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant AutoCompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownedController!).removeListener(
        _onTextChanged,
      );
      _ownedController?.dispose();
      _ownedController = widget.controller == null
          ? TextEditingController()
          : null;
      _controller.addListener(_onTextChanged);
      _load();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    _groupNode.dispose();
    _optionsNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.trim() == _filter) return;
    _load();
  }

  Future<void> _load() async {
    final filter = _controller.text.trim();
    final request = ++_request;
    _filter = filter;
    final options = await widget.getOptions(filter);
    if (!mounted || request != _request) return;
    setState(() {
      _options = options.where((o) => o != filter).toList();
    });
  }

  void _focusFirstOption() {
    for (final node in _optionsNode.traversalDescendants) {
      node.requestFocus();
      return;
    }
  }

  void _select(String option) {
    _controller.value = TextEditingValue(
      text: option,
      selection: TextSelection.collapsed(offset: option.length),
    );
    if (_groupNode.hasFocus) FocusManager.instance.primaryFocus?.unfocus();
    widget.onSelected?.call(option);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _groupNode,
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (_) => setState(() {}),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.arrowDown):
                  _FocusFirstOptionIntent(),
            },
            child: Actions(
              actions: {_FocusFirstOptionIntent: _focusFirstOptionAction},
              child:
                  widget.fieldBuilder?.call(context, _controller, _focusNode) ??
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: widget.autofocus,
                    decoration: widget.decoration,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onTapOutside: (event) => _focusNode.unfocus(),
                  ),
            ),
          ),
          AnimatedSize(
            duration: Durations.short3,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_showOptions
                ? const SizedBox(width: double.infinity)
                : TapRegion(
                    groupId: EditableText,
                    child: Focus(
                      focusNode: _optionsNode,
                      canRequestFocus: false,
                      skipTraversal: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: [
                              for (final option in _options)
                                CallbackShortcuts(
                                  bindings: {
                                    const SingleActivator(
                                      LogicalKeyboardKey.enter,
                                    ): () =>
                                        _select(option),
                                    const SingleActivator(
                                      LogicalKeyboardKey.numpadEnter,
                                    ): () =>
                                        _select(option),
                                  },
                                  child: CommonBadge(
                                    name: option,
                                    onTap: () => _select(option),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FocusFirstOptionIntent extends Intent {
  const _FocusFirstOptionIntent();
}

// stays disabled while there are no suggestions so the key event falls through
// to the text field
class _FocusFirstOptionAction extends CallbackAction<_FocusFirstOptionIntent> {
  final bool Function() isEnabledCallback;

  _FocusFirstOptionAction({
    required super.onInvoke,
    required this.isEnabledCallback,
  });

  @override
  bool isEnabled(_FocusFirstOptionIntent intent) => isEnabledCallback();

  @override
  bool consumesKey(_FocusFirstOptionIntent intent) => isEnabled(intent);
}
