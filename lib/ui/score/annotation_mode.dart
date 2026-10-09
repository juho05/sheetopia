/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';
import 'package:sheetopia/ui/annotate/pan_zoom_overlay.dart';

// Pan and zoom of a viewport sized scene. The scene never gets smaller than
// the viewport and never leaves it.
class ViewTransform extends ChangeNotifier implements PanZoomTarget {
  static const double maxScale = 8;

  Matrix4 _value = Matrix4.identity();

  Size _viewport = Size.zero;

  // Silent, it is set while the scene is laid out.
  set viewport(Size viewport) {
    if (viewport == _viewport) return;
    _viewport = viewport;
    _value = _clamp(_value);
  }

  @override
  bool get isReady => !_viewport.isEmpty;

  @override
  Matrix4 get value => _value;

  @override
  set value(Matrix4 value) {
    final clamped = _clamp(value);
    if (clamped == _value) return;
    _value = clamped;
    notifyListeners();
  }

  double get scale => _value.storage[0];

  Offset get offset {
    final translation = _value.getTranslation();
    return Offset(translation.x, translation.y);
  }

  void reset() => value = Matrix4.identity();

  Matrix4 _clamp(Matrix4 matrix) {
    final scale = matrix.storage[0].clamp(1.0, maxScale);
    final translation = matrix.getTranslation();
    return Matrix4.identity()
      ..translateByDouble(
        translation.x.clamp(_viewport.width * (1 - scale), 0.0),
        translation.y.clamp(_viewport.height * (1 - scale), 0.0),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }
}

// Annotating right inside the score viewer. Active as long as there is a view
// model, which always belongs to the score of the shown document.
class AnnotationMode extends ChangeNotifier {
  final ScoresRepository _repo;

  final ViewTransform transform = ViewTransform();

  AnnotateViewModel? _viewModel;

  AnnotateViewModel? get viewModel => _viewModel;

  bool get active => _viewModel != null;

  // the tools of a new view model continue from the last one
  AnnotateViewModel? _previous;

  bool _toolbarAtTop = false;

  bool get toolbarAtTop => _toolbarAtTop;

  // kept current by the file view
  int pageIndex = 0;
  double pageMaxSide = 0;
  double? Function(int pageIndex)? pageAspect;

  // set by the file view if it can be annotated
  void Function()? onEnterRequested;

  AnnotationMode({required this._repo});

  void toggle() {
    if (active) {
      exit();
    } else {
      onEnterRequested?.call();
    }
  }

  // By stylus only the stylus draws at first, otherwise the draw mode starts
  // like on the annotate page.
  AnnotateViewModel enter({
    required String scoreId,
    required Map<int, List<Stroke>> pages,
    String? spillScoreId,
    Map<int, List<Stroke>>? spillPages,
    required bool toolbarAtTop,
    required bool byStylus,
  }) {
    _toolbarAtTop = toolbarAtTop;
    final viewModel = AnnotateViewModel(
      repo: _repo,
      scoreId: scoreId,
      pages: pages,
      spillScoreId: spillScoreId,
      spillPages: spillPages,
      toolsFrom: _previous,
      drawMode: byStylus ? false : AnnotateViewModel.defaultDrawMode,
    );
    _replace(viewModel);
    return viewModel;
  }

  // Without pages the view model loads them itself.
  void switchScore(
    String scoreId,
    Map<int, List<Stroke>>? pages, {
    String? spillScoreId,
    Map<int, List<Stroke>>? spillPages,
  }) {
    if (!active) return;
    _replace(
      AnnotateViewModel(
        repo: _repo,
        scoreId: scoreId,
        pages: pages,
        spillScoreId: spillScoreId,
        spillPages: spillPages,
        toolsFrom: _viewModel,
      ),
    );
  }

  void exit() {
    if (active) _replace(null);
  }

  void save() => _viewModel?.saveAll();

  void paste() => _viewModel?.pasteInto(pageIndex);

  void _replace(AnnotateViewModel? viewModel) {
    final old = _viewModel;
    if (old != null) {
      _previous = old;
      old.saveAll().whenComplete(old.dispose);
    }
    viewModel?.pageAspect = (index) => pageAspect?.call(index);
    _viewModel = viewModel;
    transform.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _viewModel?.saveAll();
    transform.dispose();
    super.dispose();
  }
}
