/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/settings/page_crop.dart';

class PageCropViewModel extends ChangeNotifier {
  final PageCropSettings _settings;

  bool _enabled = false;

  bool get enabled => _enabled;

  double _paddingPercent = 0;

  double get paddingPercent => _paddingPercent;

  PageCropViewModel({required this._settings}) {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _enabled = _settings.enabled;
    _paddingPercent = _settings.paddingPercent;
    notifyListeners();
  }

  void updateEnabled(bool value) {
    _settings.enabled = value;
  }

  void dragPaddingPercent(double value) {
    _paddingPercent = value;
    notifyListeners();
  }

  void updatePaddingPercent(double value) {
    _settings.paddingPercent = value;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
