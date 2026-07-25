/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// modified version of:
// https://github.com/yurii-khi/text_scroll/blob/dev/lib/text_scroll.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// TextScroll widget automatically scrolls provided [text] according
/// to custom settings, in order to achieve 'marquee' text effect.
///
/// ### Example:
///
/// ```dart
/// TextScroll(
///     'This is the sample text for Flutter TextScroll widget. ',
///     mode: TextScrollMode.bouncing,
///     velocity: Velocity(pixelsPerSecond: Offset(150, 0)),
///     delayBefore: Duration(milliseconds: 500),
///     numberOfReps: 5,
///     pauseBetween: Duration(milliseconds: 50),
///     style: TextStyle(color: Colors.green),
///     textAlign: TextAlign.right,
///     selectable: true,
/// )
/// ```
class TextScroll extends StatefulWidget {
  const TextScroll(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection = TextDirection.ltr,
    this.numberOfReps,
    this.delayBefore = const Duration(seconds: 3),
    this.pauseBetween = const Duration(seconds: 3),
    this.pauseOnBounce,
    this.mode = TextScrollMode.endless,
    this.velocity = const Velocity(pixelsPerSecond: Offset(40, 0)),
    this.selectable = false,
    this.intervalSpaces = 5,
    this.fadedBorder = true,
    this.fadedBorderWidth = 0.025,
    this.fadeBorderSide = FadeBorderSide.right,
    this.fadeBorderVisibility = FadeBorderVisibility.auto,
  });

  /// The text string, that would be scrolled.
  /// In case text does fit into allocated space, it wouldn't be scrolled
  /// and would be shown as is.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll('This is the sample text for Flutter TextScroll widget.')
  /// ```
  final String text;

  /// Provides [TextAlign] alignment if text string is not long enough to be scrolled.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Short string',
  ///   textAlign: TextAlign.right,
  /// )
  /// ```
  final TextAlign? textAlign;

  /// Provides [TextDirection] - a direction in which text flows.
  /// Default is [TextDirection.ltr].
  /// Default scrolling direction would be opposite to [textDirection],
  /// e.g. for [TextDirection.rtl] scrolling would be from left to right
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. Hey! I\'m a RTL text, check me out. ',
  ///   textDirection: TextDirection.rtl,
  /// )
  /// ```
  final TextDirection textDirection;

  /// Allows to apply custom [TextStyle] to [text].
  ///
  /// `null` by default.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Styled text',
  ///   style: TextStyle(
  ///     color: Colors.red,
  ///   ),
  /// )
  /// ```
  final TextStyle? style;

  /// Limits number of scroll animation rounds.
  ///
  /// Default is [infinity].
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Limit scroll rounds to 10',
  ///   numberOfReps: 10,
  /// )
  /// ```
  final int? numberOfReps;

  /// Delay before first animation round.
  ///
  /// Default is [Duration.zero].
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Start animation after 1 sec delay',
  ///   delayBefore: Duration(seconds: 1),
  /// )
  /// ```
  final Duration? delayBefore;

  /// Determines pause interval between animation rounds.
  ///
  /// Default is [Duration.zero].
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Pause animation between rounds',
  ///   mode: TextScrollMode.bouncing,
  ///   pauseBetween: Duration(milliseconds: 300),
  /// )
  /// ```
  final Duration? pauseBetween;

  /// Determines pause interval before changing direction on a bounce.
  ///
  /// Default is [Duration.zero].
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Pause animation when text reaches the end',
  ///   mode: TextScrollMode.bouncing,
  ///   pauseOnBounce: Duration(milliseconds: 300),
  /// )
  /// ```
  final Duration? pauseOnBounce;

  /// Sets one of two different types of scrolling behavior.
  ///
  /// [TextScrollMode.endless] - default, scrolls text in one direction endlessly.
  ///
  /// [TextScrollMode.bouncing] - when [text] string is scrolled to its end,
  /// starts animation to opposite direction.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Animate text string back and forth',
  ///   mode: TextScrollMode.bouncing,
  /// )
  /// ```
  final TextScrollMode mode;

  /// Allows to customize animation speed.
  ///
  /// Default is `Velocity(pixelsPerSecond: Offset(80, 0))`
  ///
  /// ### Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Animate text at 200px per second',
  ///   velocity: Velocity(pixelsPerSecond: Offset(200, 0)),
  /// )
  final Velocity velocity;

  /// Allows users to select provided [text], copy it to clipboard etc.
  ///
  /// Default is `false`.
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'Selectable text',
  ///   selectable: true,
  /// )
  /// ```
  final bool selectable;

  /// Adds blank spaces between two nearby text sentences
  /// in case of [TextScrollMode.endless]
  ///
  /// Default is `1`.
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'This is the sample text for Flutter TextScroll widget. ',
  ///   blankSpaces: 10,
  /// )
  /// ```
  final int? intervalSpaces;

  /// Fades the text out to the left and right edges of the widget.
  /// Default is `false`.
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'This is the sample text for Flutter TextScroll widget. ',
  ///   fadedBorder: true,
  /// )
  /// ```
  final bool fadedBorder;

  /// Sets width of the faded border.
  /// Default is `0.2`.
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///   'This is the sample text for Flutter TextScroll widget. ',
  ///   fadedBorder: true,
  ///   fadedBorderWidth: 0.25,
  /// )
  /// ```
  final double? fadedBorderWidth;

  /// Sets which side of the widget should be faded.
  /// Default is [FadeBorderSide.both].
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///  'This is the sample text for Flutter TextScroll widget. ',
  ///  fadedBorder: true,
  ///  fadeBorderSide: FadeBorderSide.left,
  ///  )
  ///  ```
  final FadeBorderSide fadeBorderSide;

  /// Sets when the fadeBorder should be shown.
  /// Default is [FadeBorderSide.auto].
  ///
  /// Example:
  ///
  /// ```dart
  /// TextScroll(
  ///  'This is the sample text for Flutter TextScroll widget. ',
  ///  fadedBorder: true,
  ///  fadeBorderVisibility: FadeBorderVisibility.always,
  ///  )
  ///  ```
  final FadeBorderVisibility fadeBorderVisibility;

  @override
  State<TextScroll> createState() => _TextScrollState();
}

class _TextScrollState extends State<TextScroll>
    with SingleTickerProviderStateMixin {
  /// ignored below this, so a marquee never runs for a sub pixel overflow
  static const double _minOverflow = 1;

  AnimationController? _animation;

  AnimationController get _controller =>
      _animation ??= AnimationController(vsync: this);

  double _from = 0;
  double _to = 0;

  int _runId = 0;
  int _counter = 0;
  Object? _runSignature;

  String? _measuredText;
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;
  TextDirection? _measuredDirection;
  int? _measuredSpaces;
  double _textWidth = 0;
  double _roundExtent = 0;

  @override
  void dispose() {
    _runId++;
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.intervalSpaces == null || widget.mode == TextScrollMode.endless,
      'intervalSpaces is only available in TextScrollMode.endless mode',
    );
    assert(
      !widget.fadedBorder ||
          (widget.fadedBorder &&
              widget.fadedBorderWidth != null &&
              widget.fadedBorderWidth! > 0 &&
              widget.fadedBorderWidth! <= 1),
      'fadedBorderInterval must be between 0 and 1 when fadedBorder is true',
    );

    _measure(
      DefaultTextStyle.of(context).style.merge(widget.style),
      MediaQuery.textScalerOf(context),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final scrolls =
            maxWidth.isFinite && _textWidth - maxWidth > _minOverflow;
        _scheduleRun(scrolls: scrolls, maxWidth: maxWidth);

        return _withFadedBorder(
          scrolls: scrolls,
          child: Directionality(
            textDirection: widget.textDirection,
            child: scrolls ? _buildScrolling() : _buildStatic(maxWidth),
          ),
        );
      },
    );
  }

  Widget _buildStatic(double maxWidth) {
    final text = _buildText(widget.text);
    if (!maxWidth.isFinite) return text;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: maxWidth),
      child: text,
    );
  }

  Widget _buildScrolling() {
    final text = widget.mode == TextScrollMode.endless
        ? "${widget.text}$_spaces${widget.text}"
        : widget.text;

    return RepaintBoundary(
      child: ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          maxWidth: double.infinity,
          fit: OverflowBoxFit.deferToChild,
          child: AnimatedBuilder(
            animation: _controller,
            child: _buildText(text),
            builder: (context, child) =>
                Transform.translate(offset: Offset(_offset, 0), child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    if (widget.selectable) {
      return SelectableText(
        text,
        style: widget.style,
        textAlign: widget.textAlign,
      );
    }
    return Text(text, style: widget.style, textAlign: widget.textAlign);
  }

  double get _offset {
    final position = _from + (_to - _from) * _controller.value;
    return widget.textDirection == TextDirection.rtl ? position : -position;
  }

  String get _spaces => '\u{00A0}' * (widget.intervalSpaces ?? 1);

  void _measure(TextStyle style, TextScaler textScaler) {
    if (_measuredText == widget.text &&
        _measuredStyle == style &&
        _measuredScaler == textScaler &&
        _measuredDirection == widget.textDirection &&
        _measuredSpaces == widget.intervalSpaces) {
      return;
    }
    _measuredText = widget.text;
    _measuredStyle = style;
    _measuredScaler = textScaler;
    _measuredDirection = widget.textDirection;
    _measuredSpaces = widget.intervalSpaces;

    _textWidth = _widthOf(widget.text, style, textScaler);
    _roundExtent = widget.mode == TextScrollMode.endless
        ? _widthOf("${widget.text}$_spaces", style, textScaler)
        : 0;
  }

  double _widthOf(String text, TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: widget.textDirection,
      textScaler: textScaler,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout();
    final width = painter.size.width;
    painter.dispose();
    return width;
  }

  void _scheduleRun({required bool scrolls, required double maxWidth}) {
    final signature = (
      scrolls,
      maxWidth,
      widget.text,
      widget.mode,
      widget.velocity,
      widget.numberOfReps,
      widget.intervalSpaces,
      widget.textDirection,
    );
    if (signature == _runSignature) return;
    _runSignature = signature;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || signature != _runSignature) return;
      _run(scrolls: scrolls, maxWidth: maxWidth);
    });
  }

  Future<void> _run({required bool scrolls, required double maxWidth}) async {
    final runId = ++_runId;
    _from = 0;
    _to = 0;
    _counter = 0;
    _animation?.stop();
    _animation?.value = 0;
    if (!scrolls) return;

    if (widget.delayBefore != null) {
      await Future<void>.delayed(widget.delayBefore!);
      if (!_stillRunning(runId)) return;
    }

    while (_stillRunning(runId)) {
      final maxReps = widget.numberOfReps;
      if (maxReps != null && _counter >= maxReps) return;
      _counter++;

      final completed = widget.mode == TextScrollMode.bouncing
          ? await _runBouncing(runId, maxWidth)
          : await _runEndless(runId);
      if (!completed) return;
    }
  }

  Future<bool> _runEndless(int runId) async {
    if (!await _animate(runId, 0, _roundExtent)) return false;

    _from = 0;
    _to = 0;
    _controller.value = 0;

    return _pause(runId, widget.pauseBetween);
  }

  Future<bool> _runBouncing(int runId, double maxWidth) async {
    final extent = _textWidth - maxWidth;
    if (!await _animate(runId, 0, extent)) return false;
    if (!await _pause(runId, widget.pauseOnBounce)) return false;
    if (!await _animate(runId, extent, 0)) return false;
    return _pause(runId, widget.pauseBetween);
  }

  Future<bool> _animate(int runId, double from, double to) async {
    final duration = _durationFor((to - from).abs());
    if (duration == Duration.zero) return false;

    _from = from;
    _to = to;
    _controller.duration = duration;
    try {
      await _controller.forward(from: 0).orCancel;
    } on TickerCanceled {
      return false;
    }
    return _stillRunning(runId);
  }

  Future<bool> _pause(int runId, Duration? duration) async {
    if (duration == null) return true;
    await Future<void>.delayed(duration);
    return _stillRunning(runId);
  }

  Duration _durationFor(double extent) {
    if (widget.velocity.pixelsPerSecond.dx == 0) return Duration.zero;
    return Duration(
      milliseconds: (extent * 1000 / widget.velocity.pixelsPerSecond.dx)
          .round(),
    );
  }

  bool _stillRunning(int runId) => mounted && runId == _runId;

  Widget _withFadedBorder({required bool scrolls, required Widget child}) {
    if (!widget.fadedBorder) return child;
    if (widget.fadeBorderVisibility == FadeBorderVisibility.auto && !scrolls) {
      return child;
    }

    final List<Color> colors = List.generate(
      1 ~/ widget.fadedBorderWidth! - 1,
      (index) => Colors.transparent,
      growable: true,
    );
    if (widget.fadeBorderSide == FadeBorderSide.both ||
        widget.fadeBorderSide == FadeBorderSide.left) {
      colors.insert(0, Colors.black);
    } else {
      colors.add(Colors.transparent);
    }
    if (widget.fadeBorderSide == FadeBorderSide.both ||
        widget.fadeBorderSide == FadeBorderSide.right) {
      colors.add(Colors.black);
    } else {
      colors.add(Colors.transparent);
    }

    final List<double> stops = List.generate(
      1 ~/ widget.fadedBorderWidth!,
      (index) => (index + 1) * widget.fadedBorderWidth!,
      growable: true,
    );
    stops.insert(0, 0);

    return ShaderMask(
      blendMode: BlendMode.dstOut,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors,
        stops: stops,
      ).createShader(rect),
      child: child,
    );
  }
}

/// Animation types for [TextScroll] widget.
///
/// [endless] - scrolls text in one direction endlessly.
///
/// [bouncing] - when text is scrolled to its end,
/// starts animation to opposite direction.
enum TextScrollMode { bouncing, endless }

/// Side of the text border to fade out.
///
/// [left] - fade out left side of the text.
/// [right] - fade out right side of the text.
/// [both] - fade out both sides of the text.
enum FadeBorderSide { left, right, both }

/// Sets when the fade border will be applied
///
/// [always] - always show the border, independent of the text length
/// [auto] - show the border only when the text is wider than the widget
enum FadeBorderVisibility { always, auto }
