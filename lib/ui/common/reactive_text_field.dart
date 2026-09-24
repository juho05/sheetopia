/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// Reduced port of ReactiveTextField from package:reactive_forms
// (Copyright 2020 Joan Pablo Jimenez Milian, MIT license) which still builds
// on package:flutter/material.dart.

import 'package:material_ui/material_ui.dart';
import 'package:reactive_forms/reactive_forms.dart' hide ReactiveTextField;

class ReactiveTextField<T> extends ReactiveFormField<T, String> {
  final TextEditingController? _textController;

  ReactiveTextField({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.focusNode,
    InputDecoration decoration = const InputDecoration(),
    bool obscureText = false,
    int? maxLines = 1,
    int? minLines,
    Iterable<String>? autofillHints,
    TextEditingController? controller,
    ReactiveFormFieldCallback<T>? onSubmitted,
    TapRegionCallback? onTapOutside,
  }) : _textController = controller,
       super(
         builder: (ReactiveFormFieldState<T, String> field) {
           final state = field as _ReactiveTextFieldState<T>;
           final effectiveDecoration = decoration.applyDefaults(
             Theme.of(state.context).inputDecorationTheme,
           );
           return TextField(
             controller: state._textController,
             focusNode: state.focusNode,
             decoration: effectiveDecoration.copyWith(
               errorText: state.errorText,
             ),
             obscureText: obscureText,
             maxLines: maxLines,
             minLines: minLines,
             enabled: field.control.enabled,
             autofillHints: autofillHints,
             onSubmitted: onSubmitted != null
                 ? (_) => onSubmitted(field.control)
                 : null,
             onChanged: field.didChange,
             onTapOutside: onTapOutside,
           );
         },
       );

  @override
  ReactiveFormFieldState<T, String> createState() =>
      _ReactiveTextFieldState<T>();
}

class _ReactiveTextFieldState<T>
    extends ReactiveFocusableFormFieldState<T, String> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final initialValue = value;
    _textController =
        (widget as ReactiveTextField<T>)._textController ??
        TextEditingController();
    _textController.text = initialValue == null ? '' : initialValue.toString();
  }

  @override
  void onControlValueChanged(dynamic value) {
    final effectiveValue = (value == null) ? '' : value.toString();
    _textController.value = _textController.value.copyWith(
      text: effectiveValue,
      selection: TextSelection.collapsed(offset: effectiveValue.length),
      composing: TextRange.empty,
    );
    super.onControlValueChanged(value);
  }

  @override
  void dispose() {
    if ((widget as ReactiveTextField<T>)._textController == null) {
      _textController.dispose();
    }
    super.dispose();
  }
}
