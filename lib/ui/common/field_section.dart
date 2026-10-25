/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/common/heading.dart';

/// A titled section without a background, e.g. one filter in a dialog.
class FieldSection extends StatelessWidget {
  static const double _headerHeight = 28;
  static const double _gap = 4;

  /// the empty space badge lists reserve above their badges for the remove
  /// buttons, it overlaps the header so badges line up with other inputs
  static const double _badgeOffset = 8;

  static const double _buttonSize = 40;

  /// the visual gap between the top of a section and its heading text,
  /// measured, so elements after sections get the same visual distance
  static const double headingInset = 10;

  final String title;
  final List<Widget> trailing;
  final Widget child;

  /// the child is a badge list that reserves space for remove buttons
  final bool badges;

  const FieldSection({
    super.key,
    required this.title,
    this.trailing = const [],
    this.badges = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: _headerHeight + _gap - (badges ? _badgeOffset : 0),
          ),
          child: child,
        ),
        SizedBox(
          height: _headerHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Heading(text: title),
          ),
        ),
        if (trailing.isNotEmpty)
          Positioned(
            top: (_headerHeight - _buttonSize) / 2,
            right: 0,
            height: _buttonSize,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: trailing,
            ),
          ),
      ],
    );
  }
}
