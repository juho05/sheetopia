/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/settings/page_turning.dart';

class PageTurningViewModel extends ChangeNotifier {
  final PageTurningSettings _settings;

  bool _flashOnPageTurn = false;

  bool get flashOnPageTurn => _flashOnPageTurn;

  bool _gradualPageTurns = false;

  bool get gradualPageTurns => _gradualPageTurns;

  PageTurningViewModel({required this._settings}) {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _flashOnPageTurn = _settings.flashOnPageTurn;
    _gradualPageTurns = _settings.gradualPageTurns;
    notifyListeners();
  }

  void updateFlashOnPageTurn(bool value) {
    _settings.flashOnPageTurn = value;
  }

  void updateGradualPageTurns(bool value) {
    _settings.gradualPageTurns = value;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
