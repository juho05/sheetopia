/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';

class SetlistBubble extends StatelessWidget {
  final bool visible;
  final String name;
  final int index;
  final int length;
  final void Function() onTap;

  const SetlistBubble({
    super.key,
    required this.visible,
    required this.name,
    required this.index,
    required this.length,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadingOverlay(
      visible: visible,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "${index + 1} of $length",
                      style: TextStyle(color: Colors.white.withAlpha(200)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
