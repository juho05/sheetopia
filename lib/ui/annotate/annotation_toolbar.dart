/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/common/confirmation.dart';

Map<ShortcutActivator, VoidCallback> annotationShortcuts(
  AnnotateViewModel viewModel,
) {
  final bool isApple = Platform.isMacOS || Platform.isIOS;
  return {
    SingleActivator(
      LogicalKeyboardKey.keyZ,
      control: !isApple,
      meta: isApple,
      includeRepeats: false,
    ): viewModel.undo,
    SingleActivator(
      LogicalKeyboardKey.keyY,
      control: !isApple,
      meta: isApple,
      includeRepeats: false,
    ): viewModel.redo,
    SingleActivator(
      LogicalKeyboardKey.keyZ,
      control: !isApple,
      meta: isApple,
      shift: true,
      includeRepeats: false,
    ): viewModel.redo,
  };
}

class AnnotationToolbar extends StatefulWidget {
  final AnnotateViewModel viewModel;
  final bool atTop;
  final bool slideIn;
  final double bottomPadding;
  final VoidCallback onPaste;
  final VoidCallback? onDone;

  final double Function() pageMaxSidePx;

  const AnnotationToolbar({
    super.key,
    required this.viewModel,
    required this.onPaste,
    required this.pageMaxSidePx,
    this.atTop = false,
    this.slideIn = false,
    this.bottomPadding = 16,
    this.onDone,
  });

  @override
  State<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends State<AnnotationToolbar> {
  Offset? _widthPreviewAt;

  void _showWidthPreview(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() => _widthPreviewAt = box.globalToLocal(globalPosition));
  }

  void _hideWidthPreview() {
    if (_widthPreviewAt != null) setState(() => _widthPreviewAt = null);
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = _Toolbar(
      viewModel: widget.viewModel,
      onWidthPreview: _showWidthPreview,
      onWidthPreviewEnd: _hideWidthPreview,
      onPaste: widget.onPaste,
      onDone: widget.onDone,
    );
    return Stack(
      children: [
        Align(
          alignment: widget.atTop
              ? Alignment.topCenter
              : Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, widget.bottomPadding),
            child: !widget.slideIn
                ? toolbar
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: widget.atTop ? -1.5 : 1.5, end: 0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (context, dy, child) => FractionalTranslation(
                      translation: Offset(0, dy),
                      child: child,
                    ),
                    child: toolbar,
                  ),
          ),
        ),
        if (_widthPreviewAt != null)
          _WidthPreview(
            viewModel: widget.viewModel,
            at: _widthPreviewAt!,
            below: widget.atTop,
            pageMaxSidePx: widget.pageMaxSidePx(),
          ),
      ],
    );
  }
}

// A bare circle at the true on-screen stroke size, floating just above the
// finger while the width slider is dragged, horizontally centered on it.
class _WidthPreview extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final Offset at;
  final bool below;
  final double pageMaxSidePx;

  static const double _gap = 36;

  const _WidthPreview({
    required this.viewModel,
    required this.at,
    required this.below,
    required this.pageMaxSidePx,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final d = max(viewModel.width * pageMaxSidePx, 2.0);
        final fill = viewModel.eraser
            ? Colors.black.withValues(alpha: 0.1)
            : Color.alphaBlend(Color(viewModel.colorValue), Colors.white);
        return Positioned(
          left: at.dx - d / 2,
          top: below ? at.dy + _gap : at.dy - _gap - d,
          child: IgnorePointer(
            child: Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final void Function(Offset globalPosition) onWidthPreview;
  final VoidCallback onWidthPreviewEnd;
  final VoidCallback onPaste;
  final VoidCallback? onDone;

  const _Toolbar({
    required this.viewModel,
    required this.onWidthPreview,
    required this.onWidthPreviewEnd,
    required this.onPaste,
    required this.onDone,
  });

  Future<void> _clear(BuildContext context) async {
    final confirmed = await ConfirmationDialog.showYesNo(
      context,
      title: "Clear all annotations?",
      message: "This removes every stroke on all pages.",
    );
    if (confirmed == true) viewModel.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(MediaQuery.of(context).size.width - 32, 620),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 4,
                children: [
                  IconButton(
                    tooltip: !viewModel.drawMode
                        ? "Move"
                        : viewModel.lasso
                        ? "Select"
                        : "Draw",
                    isSelected: viewModel.drawMode,
                    onPressed: viewModel.toggleDrawMode,
                    icon: Icon(
                      !viewModel.drawMode
                          ? Icons.back_hand
                          : viewModel.lasso
                          ? Symbols.lasso_select
                          : Symbols.stylus,
                    ),
                  ),
                  if (viewModel.lasso)
                    _LassoTools(viewModel: viewModel, onPaste: onPaste)
                  else
                    _PenTools(
                      viewModel: viewModel,
                      onWidthPreview: onWidthPreview,
                      onWidthPreviewEnd: onWidthPreviewEnd,
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Undo",
                        icon: const Icon(Icons.undo),
                        onPressed: viewModel.canUndo ? viewModel.undo : null,
                      ),
                      IconButton(
                        tooltip: "Redo",
                        icon: const Icon(Icons.redo),
                        onPressed: viewModel.canRedo ? viewModel.redo : null,
                      ),
                      if (!viewModel.lasso)
                        IconButton(
                          tooltip: "Clear all",
                          icon: const Icon(Icons.delete_outline),
                          onPressed: viewModel.hasAnnotations
                              ? () => _clear(context)
                              : null,
                        ),
                      if (viewModel.lasso || onDone != null)
                        IconButton(
                          tooltip: "Done",
                          icon: const Icon(Icons.check),
                          onPressed: viewModel.lasso
                              ? () => viewModel.setColor(viewModel.colorValue)
                              : onDone,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PenTools extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final void Function(Offset globalPosition) onWidthPreview;
  final VoidCallback onWidthPreviewEnd;

  const _PenTools({
    required this.viewModel,
    required this.onWidthPreview,
    required this.onWidthPreviewEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            for (final color in AnnotateViewModel.palette)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => viewModel.setColor(color),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.alphaBlend(Color(color), Colors.white),
                      border: Border.all(
                        color:
                            !viewModel.eraser && viewModel.colorValue == color
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width:
                            !viewModel.eraser && viewModel.colorValue == color
                            ? 3
                            : 1,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: viewModel.setEraser,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: viewModel.eraser
                        ? Border.all(color: theme.colorScheme.primary, width: 3)
                        : null,
                  ),
                  child: const Icon(Symbols.ink_eraser, size: 20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: viewModel.setLasso,
                child: const SizedBox.square(
                  dimension: 26,
                  child: Icon(Symbols.lasso_select, size: 20),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 110,
          height: 40,
          child: Listener(
            onPointerDown: (e) => onWidthPreview(e.position),
            onPointerMove: (e) => onWidthPreview(e.position),
            onPointerUp: (_) => onWidthPreviewEnd(),
            onPointerCancel: (_) => onWidthPreviewEnd(),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 4,
              ),
              child: Slider(
                value: viewModel.widthFraction,
                onChanged: viewModel.setWidthFraction,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LassoTools extends StatelessWidget {
  final AnnotateViewModel viewModel;
  final VoidCallback onPaste;

  const _LassoTools({required this.viewModel, required this.onPaste});

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.hasSelection;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: "Delete",
          icon: const Icon(Icons.delete),
          onPressed: selected ? viewModel.deleteSelection : null,
        ),
        IconButton(
          tooltip: "Cut",
          icon: const Icon(Icons.content_cut),
          onPressed: selected ? viewModel.cutSelection : null,
        ),
        IconButton(
          tooltip: "Copy",
          icon: const Icon(Icons.content_copy),
          onPressed: selected ? viewModel.copySelection : null,
        ),
        IconButton(
          tooltip: "Paste",
          icon: const Icon(Icons.content_paste),
          onPressed: viewModel.canPaste ? onPaste : null,
        ),
      ],
    );
  }
}
