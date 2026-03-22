/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';

class DebugViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  Level _level;
  Level get level => _level;

  DebugViewModel({required SettingsRepository settings})
    : _settings = settings,
      _level = settings.logging.level {
    _settings.logging.addListener(_onSettingsChanged);
  }

  set level(Level level) {
    _settings.logging.level = level;
  }

  void _onSettingsChanged() {
    _level = _settings.logging.level;
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.logging.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
