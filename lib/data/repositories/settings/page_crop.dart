/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

class PageCropSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const double maxPaddingPercent = 5;
  static const double paddingPercentStep = 0.25;

  static const String _enabledKey = "page_crop.enabled";
  static const bool _enabledDefault = false;
  bool _enabled = _enabledDefault;
  bool get enabled => _enabled;

  static const String _paddingPercentKey = "page_crop.padding_percent";
  static const double _paddingPercentDefault = 1;
  double _paddingPercent = _paddingPercentDefault;
  double get paddingPercent => _paddingPercent;

  PageCropSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading page crop settings");
    _enabled = (await _repo.loadBool(_enabledKey)) ?? _enabledDefault;
    _paddingPercent =
        ((await _repo.loadDouble(_paddingPercentKey)) ?? _paddingPercentDefault)
            .clamp(0.0, maxPaddingPercent);
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting page crop settings");
    _enabled = _enabledDefault;
    _paddingPercent = _paddingPercentDefault;
    notifyListeners();
    _repo.remove(_enabledKey);
    _repo.remove(_paddingPercentKey);
  }

  set enabled(bool value) {
    if (value == _enabled) return;
    Log.debug("page crop: $value");
    _enabled = value;
    notifyListeners();
    _repo.store(_enabledKey, _enabled);
  }

  set paddingPercent(double value) {
    if (value == _paddingPercent) return;
    Log.debug("page crop padding: $value%");
    _paddingPercent = value;
    notifyListeners();
    _repo.store(_paddingPercentKey, _paddingPercent);
  }
}
