/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

export 'package:flutter_fullscreen/flutter_fullscreen.dart'
    show FullScreenListener;

/// Drop-in replacement for [FullScreen] that tracks the state optimistically.
///
/// On Windows, fullscreen is handled by the runner (`flutter_window.cpp`)
/// instead of window_manager. window_manager resizes the window several times
/// per transition, which makes Flutter lay out every intermediate size. It also
/// never reports entering fullscreen:
/// https://github.com/leanflutter/window_manager/issues/560
class AppFullScreen with FullScreenListener {
  static final AppFullScreen _instance = AppFullScreen._();

  static const _windowChannel = MethodChannel('sheetopia/window');

  AppFullScreen._();

  final ObserverList<FullScreenListener> _listeners = ObserverList();

  bool _state = false;

  static bool get supportWeb => FullScreen.supportWeb;

  static bool get supportWindowManager => FullScreen.supportWindowManager;

  static bool get supportMobile => FullScreen.supportMobile;

  static bool get isFullScreen => _instance._state;

  static Future<void> ensureInitialized() async {
    if (Platform.isWindows) {
      _windowChannel.setMethodCallHandler((call) async {
        if (call.method == 'onFullScreenChanged') {
          _instance._onStateChanged(call.arguments as bool);
        }
      });
      _instance._state =
          await _windowChannel.invokeMethod<bool>('isFullScreen') ?? false;
      return;
    }
    await FullScreen.ensureInitialized();
    FullScreen.addListener(_instance);
    _instance._state = FullScreen.isFullScreen;
  }

  static void addListener(FullScreenListener listener) {
    if (!_instance._listeners.contains(listener)) {
      _instance._listeners.add(listener);
    }
  }

  static void removeListener(FullScreenListener listener) =>
      _instance._listeners.remove(listener);

  static void setFullScreen(bool enabled) {
    if (Platform.isWindows) {
      _windowChannel.invokeMethod('setFullScreen', enabled);
    } else {
      FullScreen.setFullScreen(enabled);
    }
    _instance._onStateChanged(enabled);
  }

  static void setImmersive(bool immersive) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    SystemChrome.setEnabledSystemUIMode(
      immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _onStateChanged(bool state) {
    if (_state == state) return;
    _state = state;
    for (final listener in _listeners.toList()) {
      listener.onFullScreenChanged(_state, null);
      if (_state) {
        listener.onWindowEnterFullScreen(null);
      } else {
        listener.onWindowLeaveFullScreen(null);
      }
    }
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) =>
      _onStateChanged(enabled);

  @override
  void onFullScreenForcedChanged(bool forced) {
    for (final listener in _listeners.toList()) {
      listener.onFullScreenForcedChanged(forced);
    }
  }
}
