/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/dashed_badge.dart';

class SelectTagsList extends StatelessWidget {
  final Iterable<Widget> tags;
  final void Function() onAdd;
  final String addLabel;
  final IconData addIcon;

  const SelectTagsList({
    super.key,
    required this.tags,
    required this.onAdd,
    this.addLabel = "Add",
    this.addIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 4,
      runSpacing: 4,
      children: tags.followedBy([
        // aligns with the badges, which are offset by their remove button
        Padding(
          padding: const EdgeInsets.only(left: 9, top: 9),
          child: DashedBadge(onTap: onAdd, label: addLabel, icon: addIcon),
        ),
      ]).toList(),
    );
  }
}
