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
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class ScoreViewModel extends ChangeNotifier with FullScreenListener {
  final ScoresRepository _repo;

  final String _scoreId;

  String get scoreId => _scoreId;

  Score? _score;

  File? get file => _score?.file;

  FileType? get fileType => _score?.fileType;

  bool get supportsFullScreen =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  bool get isFullScreen => FullScreen.isFullScreen;

  final StreamController<bool> _pageChangedStreamController =
      StreamController.broadcast();

  Stream<bool> get pageChangedStream => _pageChangedStreamController.stream;

  StreamSubscription? _updatedScoresSub;

  ScoreViewModel({required ScoresRepository repo, required String scoreId})
    : _repo = repo,
      _scoreId = scoreId {
    _load().then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => s.any((id) => id == _scoreId))
          .listen((_) {
            _load();
          });
    });
    FullScreen.addListener(this);
    _repo.updateLastOpened(scoreId);
    showOverlay();
  }

  bool _overlayVisible = true;

  bool get overlayVisible => _overlayVisible;

  Timer? _hideOverlayTimer;

  void showOverlay() {
    _overlayVisible = true;
    notifyListeners();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      _hideOverlayTimer?.cancel();
      _hideOverlayTimer = Timer(const Duration(seconds: 3), () {
        _overlayVisible = false;
        _hideOverlayTimer = null;
        notifyListeners();
      });
    }
  }

  void onNextPage() {
    _pageChangedStreamController.add(true);
  }

  void onPrevPage() {
    _pageChangedStreamController.add(false);
  }

  Future<void> _load() async {
    final score = await _repo.getScore(_scoreId);
    _score = score;
    // TODO properly handle score == null
    notifyListeners();
  }

  @override
  void dispose() {
    _pageChangedStreamController.close();
    _hideOverlayTimer?.cancel();
    FullScreen.removeListener(this);
    _updatedScoresSub?.cancel();
    super.dispose();
  }

  void exitFullScreen() {
    _setFullScreen(false);
  }

  void toggleFullScreen() {
    _setFullScreen(!isFullScreen);
  }

  void _setFullScreen(bool fullScreen) {
    if (!supportsFullScreen || fullScreen == isFullScreen) return;
    showOverlay();
    FullScreen.setFullScreen(fullScreen);
  }

  @override
  void onFullScreenChanged(bool enabled, SystemUiMode? systemUiMode) {
    notifyListeners();
  }
}
