/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class ClearSelectionButton extends StatelessWidget {
  final void Function() onPressed;

  const ClearSelectionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Clear selection",
      onPressed: onPressed,
      icon: const Icon(Icons.close),
    );
  }
}
