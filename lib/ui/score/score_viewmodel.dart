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
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/ui/score/score_file_view.dart';
import 'package:sheetopia/ui/score/score_sequence.dart';

class ScoreViewModel extends ChangeNotifier with FullScreenListener {
  final ScoresRepository _repo;
  final MidiRepository _midiRepository;

  final ScoreFileViewController fileView = ScoreFileViewController();

  final ScoreSequence? sequence;

  String _scoreId;

  String get scoreId => _scoreId;

  // incremented on every successful switch, so a reprise (same id, same file)
  // still restarts the document
  int _switchToken = 0;

  int get switchToken => _switchToken;

  // moves on every settled switch attempt, success or failure, so a failed
  // switch cannot leave PdfViewModel._switchInFlight stuck
  int _switchSettleCount = 0;

  int get switchSettleCount => _switchSettleCount;

  late int _lastHandledIndex;
  int _switchGeneration = 0;

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

  ScoreViewModel({
    required this._repo,
    required this._midiRepository,
    required String scoreId,
    this.sequence,
  }) : _scoreId = scoreId {
    _lastHandledIndex = sequence?.position ?? -1;
    sequence?.addListener(_onSequenceChanged);
    _load().then((_) {
      _updatedScoresSub = _repo.updatedScoreIds
          .where((s) => s.any((id) => id == _scoreId))
          .listen((_) {
            _load();
          });
    });
    FullScreen.addListener(this);
    _midiRepository.addActionListener(_midiActionListener);
    _repo.updateLastOpened(scoreId);
    showOverlay();
    if (sequence != null) _pulseChrome();
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

  // chrome tied to the sequence (e.g. bubble showing score in setlist) stays up while the
  // pointer overlay does, and flashes for a moment on every sequence change
  bool _transientChromeVisible = false;

  Timer? _transientChromeTimer;

  bool get chromeVisible =>
      (supportsFullScreen && _overlayVisible) || _transientChromeVisible;

  void _pulseChrome() {
    _transientChromeVisible = true;
    _transientChromeTimer?.cancel();
    _transientChromeTimer = Timer(const Duration(seconds: 2), () {
      _transientChromeVisible = false;
      _transientChromeTimer = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void onPageTurned(bool forward) {
    _pageChangedStreamController.add(forward);
  }

  void nextPage() => fileView.nextPage();

  void prevPage() => fileView.prevPage();

  void _midiActionListener(MidiAction action) {
    switch (action) {
      case MidiAction.nextPage:
        nextPage();
      case MidiAction.prevPage:
        prevPage();
    }
  }

  Future<void> _load() async {
    final score = await _repo.getScore(_scoreId);
    _score = score;
    // TODO properly handle score == null
    notifyListeners();
  }

  void _onSequenceChanged() {
    _pulseChrome();
    final sequence = this.sequence!;
    final targetIndex = sequence.position;
    final target = sequence.currentScoreId;
    if (target == null) return;
    if (targetIndex == _lastHandledIndex) return;
    _lastHandledIndex = targetIndex;
    _switchGeneration++;
    final generation = _switchGeneration;
    switchScore(target).then((_) {
      if (generation != _switchGeneration) return;
      _switchSettleCount++;
      notifyListeners();
    });
  }

  Future<void> switchScore(String scoreId) async {
    final score = await _repo.getScore(scoreId);
    if (score == null) return;
    _scoreId = scoreId;
    _score = score;
    _switchToken++;
    notifyListeners();
    _repo.updateLastOpened(scoreId);
  }

  @override
  void dispose() {
    _pageChangedStreamController.close();
    _hideOverlayTimer?.cancel();
    _transientChromeTimer?.cancel();
    _midiRepository.removeActionListener(_midiActionListener);
    FullScreen.removeListener(this);
    _updatedScoresSub?.cancel();
    sequence?.removeListener(_onSequenceChanged);
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
