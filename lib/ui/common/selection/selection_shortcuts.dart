/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _SelectAllAction extends Action<_SelectAllIntent> {
  final void Function() _onInvoke;

  _SelectAllAction(this._onInvoke);

  // a focused text field owns ctrl+a for its own content
  @override
  bool get isActionEnabled =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() ==
      null;

  @override
  void invoke(_SelectAllIntent intent) => _onInvoke();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class SelectionShortcuts extends StatelessWidget {
  final void Function()? onSelectAll;
  final void Function()? onClearSelection;
  final FocusScopeNode? focusScopeNode;
  final Widget child;

  const SelectionShortcuts({
    super.key,
    this.onSelectAll,
    this.onClearSelection,
    this.focusScopeNode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onSelectAll = this.onSelectAll;
    final onClearSelection = this.onClearSelection;
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    return Shortcuts(
      shortcuts: {
        if (onSelectAll != null)
          SingleActivator(
            LogicalKeyboardKey.keyA,
            control: !isApple,
            meta: isApple,
          ): const _SelectAllIntent(),
        if (onClearSelection != null)
          const SingleActivator(LogicalKeyboardKey.escape):
              const _ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          if (onSelectAll != null)
            _SelectAllIntent: _SelectAllAction(onSelectAll),
          if (onClearSelection != null)
            _ClearSelectionIntent: CallbackAction<_ClearSelectionIntent>(
              onInvoke: (_) => onClearSelection(),
            ),
        },
        child: FocusScope(node: focusScopeNode, autofocus: true, child: child),
      ),
    );
  }
}
