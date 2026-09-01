/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/ui/common/fading_overlay.dart';

class DropArea extends StatefulWidget {
  final Widget child;
  final void Function(List<XFile> files) onDrop;
  final bool enabled;
  final String label;
  final IconData icon;

  const DropArea({
    super.key,
    required this.child,
    required this.onDrop,
    this.enabled = true,
    this.label = "Drop to import",
    this.icon = Icons.file_download_outlined,
  });

  @override
  State<DropArea> createState() => _DropAreaState();
}

class _DropAreaState extends State<DropArea> {
  bool _dragging = false;

  void _setDragging(bool dragging) {
    if (_dragging == dragging) return;
    setState(() => _dragging = dragging);
  }

  @override
  void didUpdateWidget(covariant DropArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _setDragging(false);
  }

  void _onDragDone(DropDoneDetails details) {
    _setDragging(false);
    if (details.files.isEmpty) return;
    widget.onDrop(details.files);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.primary
        : theme.colorScheme.onPrimary;
    return DropTarget(
      enable: widget.enabled,
      onDragEntered: (_) => _setDragging(true),
      onDragExited: (_) => _setDragging(false),
      onDragDone: _onDragDone,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: FadingOverlay(
              visible: _dragging,
              duration: const Duration(milliseconds: 150),
              child: Container(
                color: theme.colorScheme.scrim.withValues(alpha: 0.8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final iconSize = (constraints.biggest.shortestSide * 0.25)
                        .clamp(32.0, 96.0);
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: iconSize, color: labelColor),
                          const SizedBox(height: 16),
                          Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
