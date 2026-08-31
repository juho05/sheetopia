/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/practice/exercise_category.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/category_selector.dart';

typedef NewExerciseDetails = ({String name, ExerciseCategory? category});

class NewExerciseDialog extends StatefulWidget {
  final String initialName;

  const NewExerciseDialog._({required this.initialName});

  static Future<NewExerciseDetails?> show(
    BuildContext context, {
    String initialName = "",
  }) {
    return showSheetopiaDialog<NewExerciseDetails>(
      context: context,
      builder: (context) => NewExerciseDialog._(initialName: initialName),
    );
  }

  @override
  State<NewExerciseDialog> createState() => _NewExerciseDialogState();
}

class _NewExerciseDialogState extends State<NewExerciseDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  final FocusNode _focus = FocusNode();

  ExerciseCategory? _category;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  bool get _valid => _name.isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.pop(context, (name: _name, category: _category));
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
            "Create exercise",
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
          CategorySelector(
            category: _category,
            emptyLabel: "No category",
            allowCreate: true,
            onChanged: (category) => setState(() => _category = category),
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
                onPressed: _valid ? _submit : null,
                child: const Text("Create"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
