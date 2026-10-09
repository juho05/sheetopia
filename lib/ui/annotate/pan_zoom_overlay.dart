/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/ui/annotate/annotate_viewmodel.dart';

abstract class PanZoomTarget {
  bool get isReady;

  Matrix4 get value;

  set value(Matrix4 value);
}

// A ScaleGestureRecognizer that only navigates the pointers it should: a stylus
// never navigates (it always draws), a trackpad always navigates (both modes),
// and touch/mouse navigate only in pan mode (in draw mode they draw).
class _NavScaleGestureRecognizer extends ScaleGestureRecognizer {
  final bool Function() isDrawMode;

  _NavScaleGestureRecognizer({required this.isDrawMode});

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return false;
      default:
        return !isDrawMode() && super.isPointerAllowed(event);
    }
  }
}

// A stationary two-/three-finger tap: undo/redo. It never competes in the
// gesture arena, it only watches the touch pointers, so pinch-to-zoom, panning
// and drawing keep working exactly as before. The tap is discarded as soon as
// any finger travels beyond the pan slop (that is where a pinch/pan starts) or
// the fingers stay down longer than _tapTimeout.
class _MultiFingerTapRecognizer extends OneSequenceGestureRecognizer {
  static const Duration _tapTimeout = Duration(milliseconds: 400);

  void Function(int fingers)? onMultiFingerTap;
  VoidCallback? onSecondFingerDown;

  final Map<int, Offset> _origins = {};
  int _maxFingers = 0;
  bool _failed = false;
  Timer? _timeout;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      event.kind == PointerDeviceKind.touch;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.rejected);
    if (_origins.isEmpty) {
      _failed = false;
      _maxFingers = 0;
      _timeout = Timer(_tapTimeout, () => _failed = true);
    }
    _origins[event.pointer] = event.position;
    _maxFingers = max(_maxFingers, _origins.length);
    if (_origins.length == 2 && !_failed) onSecondFingerDown?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    final origin = _origins[event.pointer];
    if (origin == null) return;
    if (event is PointerMoveEvent) {
      if ((event.position - origin).distance >
          computePanSlop(event.kind, gestureSettings)) {
        _failed = true;
      }
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (event is PointerCancelEvent) _failed = true;
      _origins.remove(event.pointer);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _timeout?.cancel();
    _timeout = null;
    _origins.clear();
    final fingers = _maxFingers;
    final failed = _failed;
    _maxFingers = 0;
    _failed = false;
    if (!failed && fingers >= 2) onMultiFingerTap?.call(fingers);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  String get debugDescription => 'annotation_multi_finger_tap';
}

// Drives the target's pan/zoom directly (its own pan/scale are disabled) so a
// stylus keeps drawing on the AnnotationSurface below while everything else
// navigates. Trackpad gestures and ctrl+wheel zoom navigate in both modes; a
// finger/mouse drag follows the mode (draws in draw mode, pans in pan mode).
class PanZoomOverlay extends StatefulWidget {
  final PanZoomTarget target;
  final AnnotateViewModel viewModel;

  const PanZoomOverlay({
    super.key,
    required this.target,
    required this.viewModel,
  });

  @override
  State<PanZoomOverlay> createState() => _PanZoomOverlayState();
}

class _PanZoomOverlayState extends State<PanZoomOverlay>
    with SingleTickerProviderStateMixin {
  Offset? _referenceFocalScene;
  double _startScale = 1.0;
  PointerDeviceKind? _lastDownKind;

  // Ballistic pan/fling driven by the same simulation Android scroll views use.
  late final AnimationController _fling;
  ClampingScrollSimulation? _simX;
  ClampingScrollSimulation? _simY;
  double _lastFlingX = 0;
  double _lastFlingY = 0;
  double _flingScale = 1;

  // A trackpad's ScaleEndDetails velocity is unreliable (its pan arrives as
  // focal deltas), so we track pan velocity ourselves for the trackpad fling.
  final Stopwatch _panClock = Stopwatch();
  VelocityTracker? _panVelocity;
  Offset _panAccum = Offset.zero;

  @override
  void initState() {
    super.initState();
    _fling = AnimationController.unbounded(vsync: this)
      ..addListener(_onFlingTick);
  }

  @override
  void dispose() {
    _fling.dispose();
    super.dispose();
  }

  Offset _toScene(Offset viewportPoint) => MatrixUtils.transformPoint(
    Matrix4.inverted(widget.target.value),
    viewportPoint,
  );

  void _onScaleStart(ScaleStartDetails details) {
    _fling.stop();
    if (!widget.target.isReady) return;
    _startScale = widget.target.value.getMaxScaleOnAxis();
    _referenceFocalScene = _toScene(details.localFocalPoint);
    _panAccum = Offset.zero;
    _panClock
      ..reset()
      ..start();
    _panVelocity = VelocityTracker.withKind(PointerDeviceKind.trackpad)
      ..addPosition(_panClock.elapsed, _panAccum);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_referenceFocalScene == null || !widget.target.isReady) return;
    _panAccum += details.focalPointDelta;
    _panVelocity?.addPosition(_panClock.elapsed, _panAccum);
    if (details.scale != 1.0) {
      final currentScale = widget.target.value.getMaxScaleOnAxis();
      final scaleChange = (_startScale * details.scale) / currentScale;
      widget.target.value = widget.target.value.clone()
        ..scaleByDouble(scaleChange, scaleChange, scaleChange, 1);
    }
    final focalScene = _toScene(details.localFocalPoint);
    final delta = focalScene - _referenceFocalScene!;
    widget.target.value = widget.target.value.clone()
      ..translateByDouble(delta.dx, delta.dy, 0, 1);
    _referenceFocalScene = _toScene(details.localFocalPoint);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _referenceFocalScene = null;
    if (!widget.target.isReady) return;
    // Fling for a finger or a trackpad; a mouse drag does not fling.
    final isTrackpad = _lastDownKind == PointerDeviceKind.trackpad;
    if (_lastDownKind != PointerDeviceKind.touch && !isTrackpad) return;
    // A trackpad's ScaleEndDetails velocity is unreliable, so use our tracker.
    var velocity = isTrackpad
        ? (_panVelocity?.getVelocity().pixelsPerSecond ?? Offset.zero)
        : details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    if (speed < kMinFlingVelocity) return;
    if (speed > kMaxFlingVelocity) {
      velocity = velocity * (kMaxFlingVelocity / speed);
    }
    _simX = velocity.dx.abs() >= 1
        ? ClampingScrollSimulation(position: 0, velocity: velocity.dx)
        : null;
    _simY = velocity.dy.abs() >= 1
        ? ClampingScrollSimulation(position: 0, velocity: velocity.dy)
        : null;
    _lastFlingX = 0;
    _lastFlingY = 0;
    _flingScale = widget.target.value.getMaxScaleOnAxis();
    _fling
      ..duration = const Duration(minutes: 1)
      ..forward(from: 0);
  }

  void _onFlingTick() {
    if (!widget.target.isReady) return;
    final t =
        (_fling.lastElapsedDuration ?? Duration.zero).inMicroseconds /
        Duration.microsecondsPerSecond;
    var done = true;
    double dx = 0;
    double dy = 0;
    if (_simX != null) {
      final x = _simX!.x(t);
      dx = (x - _lastFlingX) / _flingScale;
      _lastFlingX = x;
      done = done && _simX!.isDone(t);
    }
    if (_simY != null) {
      final y = _simY!.x(t);
      dy = (y - _lastFlingY) / _flingScale;
      _lastFlingY = y;
      done = done && _simY!.isDone(t);
    }
    if (dx != 0 || dy != 0) {
      widget.target.value = widget.target.value.clone()
        ..translateByDouble(dx, dy, 0, 1);
    }
    if (done) _fling.stop();
  }

  void _onMultiFingerTap(int fingers) {
    final viewModel = widget.viewModel;
    if (fingers == 2 && viewModel.canUndo) {
      viewModel.undo();
    } else if (fingers == 3 && viewModel.canRedo) {
      viewModel.redo();
    } else {
      return;
    }
    HapticFeedback.lightImpact();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!widget.target.isReady || event is! PointerScrollEvent) return;
    if (event.scrollDelta == Offset.zero) return;
    _fling.stop();
    final value = widget.target.value;
    if (HardwareKeyboard.instance.isControlPressed) {
      final scaleChange = exp(-event.scrollDelta.dy * 0.002);
      final before = _toScene(event.localPosition);
      widget.target.value = value.clone()
        ..scaleByDouble(scaleChange, scaleChange, scaleChange, 1);
      final after = _toScene(event.localPosition);
      widget.target.value = widget.target.value.clone()
        ..translateByDouble(after.dx - before.dx, after.dy - before.dy, 0, 1);
      return;
    }
    final scale = value.getMaxScaleOnAxis();
    widget.target.value = value.clone()
      ..translateByDouble(
        -event.scrollDelta.dx / scale,
        -event.scrollDelta.dy / scale,
        0,
        1,
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) => _lastDownKind = event.kind,
          onPointerPanZoomStart: (event) => _lastDownKind = event.kind,
          onPointerSignal: _onPointerSignal,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              _NavScaleGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _NavScaleGestureRecognizer
                  >(
                    () => _NavScaleGestureRecognizer(
                      isDrawMode: () => widget.viewModel.drawMode,
                    ),
                    (recognizer) {
                      recognizer
                        ..onStart = _onScaleStart
                        ..onUpdate = _onScaleUpdate
                        ..onEnd = _onScaleEnd;
                    },
                  ),
              _MultiFingerTapRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _MultiFingerTapRecognizer
                  >(() => _MultiFingerTapRecognizer(), (recognizer) {
                    recognizer
                      // In draw mode the first finger already started a
                      // stroke. A second finger means the user is gesturing.
                      ..onSecondFingerDown = widget.viewModel.cancelTouchStroke
                      ..onMultiFingerTap = _onMultiFingerTap;
                  }),
            },
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
