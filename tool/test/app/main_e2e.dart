/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// Entry point of the E2E feature test build: the normal app plus a Flutter
// driver extension, so tool/test/harness/bin/drive.dart can inspect and
// operate a profile build the way a user would. Never shipped.
//
//   flutter build macos --profile -t tool/test/app/main_e2e.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_driver/flutter_driver.dart' show Command, Result;
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/main.dart' as app;
import 'package:sheetopia/routing/router.dart';
import 'package:sheetopia/utils/full_screen.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  enableE2eDriver();
  await app.main();
}

typedef E2eAction = Future<Object?> Function(Map<String, dynamic> args);

/// Also used by tool/screenshots/app/main_screenshots.dart, which adds its own
/// actions.
void enableE2eDriver({Map<String, E2eAction> extraActions = const {}}) {
  enableFlutterDriverExtension(
    // The driver's text entry emulation would swallow real keyboard input,
    // text is typed with the `type` action instead.
    enableTextEntryEmulation: false,
    commands: [_E2eCommandExtension(extraActions)],
  );
}

class E2eCommand extends Command {
  final String action;
  final String args;

  E2eCommand(this.action, this.args, {super.timeout});

  E2eCommand.deserialize(super.json)
    : action = json['action']!,
      args = json['args'] ?? '{}',
      super.deserialize();

  @override
  String get kind => 'e2e';

  @override
  Map<String, String> serialize() =>
      super.serialize()..addAll({'action': action, 'args': args});
}

class _JsonResult extends Result {
  final Object? data;

  const _JsonResult(this.data);

  @override
  Map<String, dynamic> toJson() => {'data': jsonEncode(data)};
}

class _E2eCommandExtension extends CommandExtension {
  final Map<String, E2eAction> extraActions;

  _E2eCommandExtension(this.extraActions);

  @override
  String get commandKind => 'e2e';

  @override
  Command deserialize(
    Map<String, String> params,
    DeserializeFinderFactory finderFactory,
    DeserializeCommandFactory commandFactory,
  ) => E2eCommand.deserialize(params);

  @override
  Future<Result> call(
    Command command,
    WidgetController prober,
    CreateFinderFactory finderFactory,
    CommandHandlerFactory handlerFactory,
  ) async {
    final c = command as E2eCommand;
    final args = (jsonDecode(c.args) as Map).cast<String, dynamic>();
    final data = switch (c.action) {
      'describe' => _describe(args),
      'screenshot' => await _screenshot(args),
      'gesture' => await _gesture(prober, args),
      'scroll' => await _scroll(prober, args),
      'key' => await _key(args),
      'type' => _type(args),
      'drop' => await _drop(args),
      'window' => await _window(args),
      'route' => _route(),
      'back' => await _back(),
      'settle' => await _settle(args),
      final action when extraActions.containsKey(action) => await extraActions[action]!(args),
      _ => throw ArgumentError('unknown e2e action ${c.action}'),
    };
    return _JsonResult(data);
  }
}

// --- describe ---------------------------------------------------------------

/// Lists what a user can see on screen: texts, tooltips (most icon buttons
/// only have those), icon buttons without tooltip, text fields,
/// switches/checkboxes and sliders, each with its rectangle in logical pixels.
/// Items behind the topmost route (e.g. under a dialog) or in inactive tabs
/// are left out unless `all` is set, then they are marked `covered`.
Map<String, Object?> _describe(Map<String, dynamic> args) {
  final view = WidgetsBinding.instance.renderViews.first;
  final screen = Offset.zero & view.size;
  final items = <Map<String, Object?>>[];
  final includeHidden = args['all'] == true;

  void add(Element element, String type, Map<String, Object?> props) {
    final ro = element.renderObject;
    if (ro is! RenderBox || !ro.attached || !ro.hasSize) return;
    final rect = MatrixUtils.transformRect(ro.getTransformTo(null), Offset.zero & ro.size);
    if (rect.isEmpty || !rect.overlaps(screen)) return;
    final hittable = _active(element);
    if (!hittable && !includeHidden) return;
    items.add({
      'type': type,
      ...props,
      'rect': [rect.left, rect.top, rect.width, rect.height].map((v) => double.parse(v.toStringAsFixed(1))).toList(),
      if (!hittable) 'covered': true,
    });
  }

  void visit(Element element) {
    final widget = element.widget;
    switch (widget) {
      case RichText():
        final text = widget.text.toPlainText(includeSemanticsLabels: false).trim();
        if (text.isNotEmpty) add(element, 'text', {'text': text});
      case Tooltip(message: final String message) when message.isNotEmpty:
        add(element, 'tooltip', {'text': message});
      case EditableText():
        add(element, 'field', {
          'text': widget.controller.text,
          'focused': widget.focusNode.hasFocus,
          if (widget.obscureText) 'obscured': true,
        });
      case Switch():
        add(element, 'switch', {'value': widget.value, 'enabled': widget.onChanged != null});
      case Checkbox():
        add(element, 'checkbox', {'value': widget.value, 'enabled': widget.onChanged != null});
      case Slider():
        add(element, 'slider', {'value': widget.value, 'min': widget.min, 'max': widget.max});
      case IconButton(:final tooltip, :final icon) when tooltip == null || tooltip.isEmpty:
        final data = icon is Icon ? icon.icon : null;
        add(element, 'button', {
          'icon': data == null ? null : '0x${data.codePoint.toRadixString(16)}',
          'enabled': widget.onPressed != null,
        });
      case Icon(:final icon):
        // Icons render their glyph as text, which means nothing to a reader.
        if (args['icons'] == true && icon != null) {
          add(element, 'icon', {'codePoint': '0x${icon.codePoint.toRadixString(16)}'});
        }
        return;
      case IndexedStack(:final index) when !includeHidden:
        // Hidden children keep their tickers, so _active can't tell them apart.
        element.visitChildren((stack) {
          var i = 0;
          stack.visitChildren((child) {
            if (i++ == (index ?? 0)) visit(child);
          });
        });
        return;
      default:
        break;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return {
    'route': _route(),
    'size': [view.size.width, view.size.height],
    'items': items,
  };
}

/// Whether the element belongs to the topmost route and an active tab.
bool _active(Element element) {
  if (!TickerMode.valuesOf(element).enabled) return false;
  final route = ModalRoute.of(element);
  return route == null || route.isCurrent;
}

// --- screenshot -------------------------------------------------------------

Future<Map<String, Object?>> _screenshot(Map<String, dynamic> args) async {
  await SchedulerBinding.instance.endOfFrame;
  final view = WidgetsBinding.instance.renderViews.first;
  // ignore: invalid_use_of_protected_member
  final layer = view.layer! as OffsetLayer;
  // The root layer is in physical pixels. pixelRatio is relative to logical
  // pixels, so at 1.0 image coordinates match the rects of describe.
  final dpr = view.flutterView.devicePixelRatio;
  final ratio = (args['pixelRatio'] as num?)?.toDouble() ?? 1.0;
  final image = await layer.toImage(
    Offset.zero & view.flutterView.physicalSize,
    pixelRatio: ratio / dpr,
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final path = args['path'] as String?;
  if (path != null) {
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    return {'path': path};
  }
  return {'png': base64Encode(bytes!.buffer.asUint8List())};
}

// --- pointer input ----------------------------------------------------------

PointerDeviceKind _kind(String? name) => switch (name ?? 'touch') {
  'touch' => PointerDeviceKind.touch,
  'stylus' => PointerDeviceKind.stylus,
  'invertedStylus' || 'eraser' => PointerDeviceKind.invertedStylus,
  'mouse' => PointerDeviceKind.mouse,
  'trackpad' => PointerDeviceKind.trackpad,
  _ => throw ArgumentError('unknown pointer kind $name'),
};

int _nextPointer = 1000;

// Velocity tracking (flings, swipes) reads the event time stamps, which
// TestGesture leaves at zero unless given.
final Stopwatch _clock = Stopwatch()..start();

Duration get _now => _clock.elapsed;

const _frame = Duration(milliseconds: 16);

/// The point at fraction [t] of a polyline whose points are evenly spaced in
/// time.
Offset _along(List<Offset> path, double t) {
  if (path.length == 1) return path.first;
  final pos = t * (path.length - 1);
  final i = pos.floor().clamp(0, path.length - 2);
  return Offset.lerp(path[i], path[i + 1], pos - i)!;
}

/// Performs one or more simultaneous pointer strokes.
///
/// `pointers`: list of `{kind, points: [[x, y], ...], buttons?}`. All pointers
/// go down together, move through their points over `durationMs` (with a move
/// every frame, like real input) and lift after an extra `holdMs`. A single
/// point is a tap (or a long press with `holdMs`).
Future<Map<String, Object?>> _gesture(WidgetController prober, Map<String, dynamic> args) async {
  final pointers = (args['pointers'] as List).cast<Map>();
  final duration = Duration(milliseconds: (args['durationMs'] as num?)?.toInt() ?? 300);
  final hold = Duration(milliseconds: (args['holdMs'] as num?)?.toInt() ?? 0);
  final paths = [
    for (final p in pointers)
      (p['points'] as List).map((pt) => Offset((pt[0] as num).toDouble(), (pt[1] as num).toDouble())).toList(),
  ];
  final gestures = <TestGesture>[];
  for (final (i, p) in pointers.indexed) {
    final gesture = await prober.createGesture(
      pointer: _nextPointer++,
      kind: _kind(p['kind'] as String?),
      // Stylus and eraser contact is the primary button too,
      // kPrimaryStylusButton is the barrel button.
      buttons: (p['buttons'] as num?)?.toInt() ?? kPrimaryButton,
    );
    await gesture.down(paths[i].first, timeStamp: _now);
    gestures.add(gesture);
  }
  final moving = paths.any((p) => p.length > 1);
  if (moving) {
    final frames = (duration.inMicroseconds / _frame.inMicroseconds).ceil().clamp(1, 1000);
    final start = _now;
    for (var f = 1; f <= frames; f++) {
      final target = start + duration * (f / frames);
      final wait = target - _now;
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      for (final (i, g) in gestures.indexed) {
        if (paths[i].length > 1) await g.moveTo(_along(paths[i], f / frames), timeStamp: _now);
      }
    }
  } else if (duration > Duration.zero && args.containsKey('durationMs')) {
    await Future<void>.delayed(duration);
  }
  if (hold > Duration.zero) await Future<void>.delayed(hold);
  for (final g in gestures) {
    await g.up(timeStamp: _now);
  }
  return {'pointers': gestures.length};
}

/// Mouse wheel or trackpad scroll at a position. Trackpads send pan/zoom
/// events like the engine does, resting before the end so they don't fling.
Future<Map<String, Object?>> _scroll(WidgetController prober, Map<String, dynamic> args) async {
  final at = Offset((args['x'] as num).toDouble(), (args['y'] as num).toDouble());
  final delta = Offset((args['dx'] as num?)?.toDouble() ?? 0, (args['dy'] as num?)?.toDouble() ?? 0);
  final kind = _kind(args['kind'] as String? ?? 'mouse');
  final pointer = TestPointer(_nextPointer++, kind);
  if (kind == PointerDeviceKind.trackpad) {
    prober.binding.handlePointerEvent(pointer.panZoomStart(at, timeStamp: _now));
    const steps = 10;
    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(_frame);
      // The pan is the fingers' movement, opposite to the scroll direction.
      prober.binding.handlePointerEvent(pointer.panZoomUpdate(at, pan: -delta * (i / steps), timeStamp: _now));
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    prober.binding.handlePointerEvent(pointer.panZoomEnd(timeStamp: _now));
    return {'scrolled': [delta.dx, delta.dy]};
  }
  prober.binding.handlePointerEvent(pointer.addPointer(location: at));
  prober.binding.handlePointerEvent(pointer.hover(at));
  prober.binding.handlePointerEvent(pointer.scroll(delta));
  prober.binding.handlePointerEvent(pointer.removePointer());
  return {'scrolled': [delta.dx, delta.dy]};
}

// --- keyboard ---------------------------------------------------------------

final Map<String, (PhysicalKeyboardKey, LogicalKeyboardKey)> _keys = {
  for (final (i, letter) in 'abcdefghijklmnopqrstuvwxyz'.split('').indexed)
    letter: (
      PhysicalKeyboardKey(0x00070004 + i),
      LogicalKeyboardKey(0x00000000061 + i),
    ),
  for (final (i, digit) in '1234567890'.split('').indexed)
    digit: (
      PhysicalKeyboardKey(0x0007001e + i),
      LogicalKeyboardKey(digit.codeUnitAt(0)),
    ),
  'enter': (PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter),
  'escape': (PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape),
  'backspace': (PhysicalKeyboardKey.backspace, LogicalKeyboardKey.backspace),
  'tab': (PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab),
  'space': (PhysicalKeyboardKey.space, LogicalKeyboardKey.space),
  'delete': (PhysicalKeyboardKey.delete, LogicalKeyboardKey.delete),
  'home': (PhysicalKeyboardKey.home, LogicalKeyboardKey.home),
  'end': (PhysicalKeyboardKey.end, LogicalKeyboardKey.end),
  'pageUp': (PhysicalKeyboardKey.pageUp, LogicalKeyboardKey.pageUp),
  'pageDown': (PhysicalKeyboardKey.pageDown, LogicalKeyboardKey.pageDown),
  'arrowLeft': (PhysicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft),
  'arrowRight': (PhysicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowRight),
  'arrowUp': (PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp),
  'arrowDown': (PhysicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown),
  for (var i = 1; i <= 12; i++)
    'f$i': (PhysicalKeyboardKey(0x0007003a + i - 1), LogicalKeyboardKey(0x00100000801 + i - 1)),
};

final Map<String, (PhysicalKeyboardKey, LogicalKeyboardKey)> _modifiers = {
  'meta': (PhysicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaLeft),
  'control': (PhysicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlLeft),
  'shift': (PhysicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftLeft),
  'alt': (PhysicalKeyboardKey.altLeft, LogicalKeyboardKey.altLeft),
};

void _dispatchKey(KeyEvent event) {
  // Mirrors what KeyEventManager does with events from the engine. The
  // focus system still receives keys as KeyMessages.
  HardwareKeyboard.instance.handleKeyEvent(event);
  // ignore: deprecated_member_use
  ServicesBinding.instance.keyEventManager.keyMessageHandler?.call(KeyMessage([event], null));
}

/// Presses `key` (see [_keys]) while holding `modifiers`
/// (meta/control/shift/alt), or only holds the modifiers down/up with
/// `hold: "down"` / `hold: "up"` so they apply to a following gesture
/// (e.g. Cmd+click, Shift+click, Ctrl+wheel).
Future<Map<String, Object?>> _key(Map<String, dynamic> args) async {
  final modifiers = ((args['modifiers'] as List?) ?? const []).cast<String>().map((m) {
    final k = _modifiers[m];
    if (k == null) throw ArgumentError('unknown modifier $m, use ${_modifiers.keys.join('/')}');
    return k;
  }).toList();
  final hold = args['hold'] as String?;
  final now = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
  if (hold != 'up') {
    for (final (p, l) in modifiers) {
      _dispatchKey(KeyDownEvent(physicalKey: p, logicalKey: l, timeStamp: now));
    }
  }
  final name = args['key'] as String?;
  if (name != null && hold == null) {
    final key = _keys[name];
    if (key == null) throw ArgumentError('unknown key $name, use ${_keys.keys.join('/')}');
    final character = name.length == 1 && modifiers.isEmpty ? name : (name == 'space' ? ' ' : null);
    _dispatchKey(KeyDownEvent(physicalKey: key.$1, logicalKey: key.$2, character: character, timeStamp: now));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    _dispatchKey(KeyUpEvent(physicalKey: key.$1, logicalKey: key.$2, timeStamp: now));
  }
  if (hold != 'down') {
    for (final (p, l) in modifiers.reversed) {
      _dispatchKey(KeyUpEvent(physicalKey: p, logicalKey: l, timeStamp: now));
    }
  }
  await SchedulerBinding.instance.endOfFrame;
  return {'key': name, 'modifiers': args['modifiers'] ?? []};
}

/// Types into the focused text field like a user would (fires onChanged).
Map<String, Object?> _type(Map<String, dynamic> args) {
  final context = FocusManager.instance.primaryFocus?.context;
  final state = context?.findAncestorStateOfType<EditableTextState>();
  if (state == null) throw StateError('no text field is focused, tap one first');
  final old = state.textEditingValue;
  final text = args['replace'] == true ? args['text'] as String : old.text + (args['text'] as String);
  state.userUpdateTextEditingValue(
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
    SelectionChangedCause.keyboard,
  );
  if (args['submit'] == true) state.performAction(state.widget.textInputAction ?? TextInputAction.done);
  return {'text': text};
}

// --- desktop integration ----------------------------------------------------

/// Simulates the desktop_drop plugin reporting files dragged onto the window.
Future<Map<String, Object?>> _drop(Map<String, dynamic> args) async {
  final paths = (args['paths'] as List).cast<String>();
  final at = [(args['x'] as num?)?.toDouble() ?? 200.0, (args['y'] as num?)?.toDouble() ?? 200.0];
  const codec = StandardMethodCodec();
  Future<void> send(String method, Object? arguments) {
    final completer = Completer<void>();
    ServicesBinding.instance.channelBuffers.push(
      'desktop_drop',
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (_) => completer.complete(),
    );
    return completer.future;
  }

  await send('entered', at);
  await send('updated', at);
  if (args['cancel'] == true) {
    await send('exited', at);
  } else {
    await send('performOperation', paths);
  }
  return {'dropped': paths};
}

Future<Map<String, Object?>> _window(Map<String, dynamic> args) async {
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    if (args['fullscreen'] case final bool fullscreen) {
      AppFullScreen.setFullScreen(fullscreen);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (args['width'] != null && args['height'] != null) {
      // A maximized window ignores setSize.
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      await windowManager.setSize(Size((args['width'] as num).toDouble(), (args['height'] as num).toDouble()));
      if (args['center'] != false) await windowManager.center();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (args['maximize'] == true) await windowManager.maximize();
  }
  await SchedulerBinding.instance.endOfFrame;
  final view = WidgetsBinding.instance.renderViews.first;
  return {
    'size': [view.size.width, view.size.height],
    'devicePixelRatio': view.flutterView.devicePixelRatio,
    'fullscreen': AppFullScreen.isFullScreen,
    'platform': Platform.operatingSystem,
  };
}

String _route() => goRouter.routerDelegate.currentConfiguration.uri.toString();

/// The message the engine sends for the Android back button.
Future<Map<String, Object?>> _back() async {
  ServicesBinding.instance.channelBuffers.push(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await SchedulerBinding.instance.endOfFrame;
  return {'route': _route()};
}

/// Waits until no frame has been scheduled for `quietMs` (default 300), or
/// `timeoutMs` (default 10000) passed. Animations that never stop (spinners)
/// hit the timeout, which is reported, not thrown.
Future<Map<String, Object?>> _settle(Map<String, dynamic> args) async {
  final quiet = Duration(milliseconds: (args['quietMs'] as num?)?.toInt() ?? 300);
  final timeout = Duration(milliseconds: (args['timeoutMs'] as num?)?.toInt() ?? 10000);
  final sw = Stopwatch()..start();
  var lastBusy = Duration.zero;
  while (sw.elapsed < timeout) {
    if (SchedulerBinding.instance.hasScheduledFrame) lastBusy = sw.elapsed;
    if (sw.elapsed - lastBusy >= quiet) return {'settled': true, 'ms': sw.elapsedMilliseconds};
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return {'settled': false, 'ms': sw.elapsedMilliseconds};
}
