/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

bool _fullScreenReady = false;

void markFullScreenReady() => _fullScreenReady = true;

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

bool get supportsFullScreen => _fullScreenReady && _isDesktop;

class PlaySession extends StatefulWidget {
  final Widget child;

  const PlaySession({super.key, required this.child});

  static PlaySessionState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PlaySessionScope>()?.session;

  static bool isActive(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_PlaySessionScope>() != null;

  @override
  State<PlaySession> createState() => PlaySessionState();
}

class PlaySessionState extends State<PlaySession> with FullScreenListener {
  bool _overlayVisible = true;

  Timer? _hideOverlayTimer;

  bool get isFullScreen => supportsFullScreen && FullScreen.isFullScreen;

  bool get overlayVisible => _overlayVisible;

  bool get backButtonVisible =>
      !isFullScreen || (Platform.isMacOS && _overlayVisible);

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    if (supportsFullScreen) FullScreen.addListener(this);
    showOverlay();
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    if (supportsFullScreen) {
      FullScreen.removeListener(this);
      if (FullScreen.isFullScreen && !Platform.isMacOS) {
        FullScreen.setFullScreen(false);
      }
    }
    WakelockPlus.disable();
    super.dispose();
  }

  void showOverlay() {
    if (!_overlayVisible) setState(() => _overlayVisible = true);
    if (!_isDesktop) return;
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 3), () {
      _hideOverlayTimer = null;
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    setState(() {});
  }

  void toggleFullScreen() => setFullScreen(!isFullScreen);

  void exitFullScreen() => setFullScreen(false);

  void setFullScreen(bool fullScreen) {
    if (!supportsFullScreen || fullScreen == isFullScreen) return;
    FullScreen.setFullScreen(fullScreen);
  }

  @override
  Widget build(BuildContext context) => _PlaySessionScope(
    session: this,
    fullScreen: isFullScreen,
    overlayVisible: _overlayVisible,
    child: Listener(
      onPointerHover: (_) => showOverlay(),
      onPointerMove: (_) => showOverlay(),
      onPointerDown: (_) => showOverlay(),
      child: widget.child,
    ),
  );
}

class _PlaySessionScope extends InheritedWidget {
  final PlaySessionState session;
  final bool fullScreen;
  final bool overlayVisible;

  const _PlaySessionScope({
    required this.session,
    required this.fullScreen,
    required this.overlayVisible,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PlaySessionScope oldWidget) =>
      fullScreen != oldWidget.fullScreen ||
      overlayVisible != oldWidget.overlayVisible;
}
