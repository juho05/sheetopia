/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/common_badge.dart';

class TagBadge extends StatelessWidget {
  final Tag tag;
  final bool tooltip;
  final void Function()? onTap;
  final void Function()? onRemove;

  const TagBadge({
    super.key,
    required this.tag,
    this.tooltip = true,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return CommonBadge(
      name: tag.name,
      color: tag.color,
      tooltip: tooltip,
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}
