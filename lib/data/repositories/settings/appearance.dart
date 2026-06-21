/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

class AppearanceSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _themeModeKey = "appearance.theme_mode";
  static const ThemeMode _themeModeDefault = ThemeMode.system;
  ThemeMode _themeMode = _themeModeDefault;
  ThemeMode get themeMode => _themeMode;

  static const String _flashOnPageTurnKey = "appearance.flash_on_page_turn";
  static const bool _flashOnPageTurnDefault = false;
  bool _flashOnPageTurn = _flashOnPageTurnDefault;
  bool get flashOnPageTurn => _flashOnPageTurn;

  AppearanceSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading appearance settings");
    _themeMode = ThemeMode.values.byName(
      (await _repo.loadString(_themeModeKey)) ?? _themeModeDefault.name,
    );
    _flashOnPageTurn =
        (await _repo.loadBool(_flashOnPageTurnKey)) ?? _flashOnPageTurnDefault;
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting appearance settings");
    _themeMode = _themeModeDefault;
    _flashOnPageTurn = _flashOnPageTurnDefault;
    notifyListeners();
    _repo.remove(_themeModeKey);
    _repo.remove(_flashOnPageTurnKey);
  }

  set themeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    Log.debug("theme mode: ${mode.name}");
    _themeMode = mode;
    notifyListeners();
    _repo.store(_themeModeKey, _themeMode.name);
  }

  set flashOnPageTurn(bool value) {
    if (value == _flashOnPageTurn) return;
    Log.debug("flash on page turn: $value");
    _flashOnPageTurn = value;
    notifyListeners();
    _repo.store(_flashOnPageTurnKey, _flashOnPageTurn);
  }
}
