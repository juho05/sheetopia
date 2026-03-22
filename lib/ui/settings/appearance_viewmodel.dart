/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/settings/appearance.dart';

class AppearanceViewModel extends ChangeNotifier {
  final AppearanceSettings _settings;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  AppearanceViewModel({required AppearanceSettings settings})
    : _settings = settings {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _mode = _settings.themeMode;
    notifyListeners();
  }

  void updateMode(ThemeMode mode) {
    _settings.themeMode = mode;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
