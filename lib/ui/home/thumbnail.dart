/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/home/thumbnail_viewmodel.dart';

class Thumbnail extends StatefulWidget {
  final Score score;
  final int width;
  final int height;
  final double devicePixelRatio;
  final BorderRadiusGeometry borderRadius;

  const Thumbnail({
    super.key,
    required this.score,
    required this.width,
    required this.height,
    required this.devicePixelRatio,
    required this.borderRadius,
  });

  @override
  State<Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  late final ThumbnailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ThumbnailViewModel(
      service: context.read(),
      score: widget.score,
      width: (widget.width * widget.devicePixelRatio).round(),
      height: (widget.height * widget.devicePixelRatio).round(),
    );
  }

  @override
  void didUpdateWidget(covariant Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_viewModel.image != null &&
        oldWidget.score.fileUpdatedAt != widget.score.fileUpdatedAt) {
      FileImage(_viewModel.image!).evict();
    }
    if (oldWidget.score.id != widget.score.id ||
        (oldWidget.score.file == null) != (widget.score.file == null) ||
        oldWidget.score.fileUpdatedAt != widget.score.fileUpdatedAt) {
      _viewModel.update(
        score: widget.score,
        width: (widget.width * widget.devicePixelRatio).round(),
        height: (widget.height * widget.devicePixelRatio).round(),
      );
    } else if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.devicePixelRatio != widget.devicePixelRatio) {
      _viewModel.updateSize(
        width: (widget.width * widget.devicePixelRatio).round(),
        height: (widget.height * widget.devicePixelRatio).round(),
      );
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Container(
            color: Colors.white,
            width: widget.width.toDouble(),
            height: widget.height.toDouble(),
            child: AnimatedOpacity(
              opacity: _viewModel.imageOpacity,
              duration: const Duration(milliseconds: 100),
              child: _viewModel.image != null
                  ? Image.file(_viewModel.image!, fit: BoxFit.cover)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
