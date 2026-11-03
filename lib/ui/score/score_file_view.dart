/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

abstract class ScoreFileView {
  void nextPage();

  void prevPage();
}

typedef ShownCrop = ({String scoreId, bool excluded});

class ScoreFileViewController extends ChangeNotifier {
  ScoreFileView? _view;

  ShownCrop? _crop;

  /// The crop exclusion of the shown document, null while unknown.
  ShownCrop? get crop => _crop;

  void attach(ScoreFileView view) => _view = view;

  void detach(ScoreFileView view) {
    if (!identical(_view, view)) return;
    _view = null;
    _setCrop(null);
  }

  void reportCrop(ScoreFileView view, ShownCrop? crop) {
    if (identical(_view, view)) _setCrop(crop);
  }

  bool _disposed = false;
  bool _notifyScheduled = false;

  void _setCrop(ShownCrop? crop) {
    if (_disposed || crop == _crop) return;
    _crop = crop;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void nextPage() => _view?.nextPage();

  void prevPage() => _view?.prevPage();
}
