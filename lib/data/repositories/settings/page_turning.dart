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

class PageTurningSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  // key predates the page turning settings
  static const String _flashOnPageTurnKey = "appearance.flash_on_page_turn";
  static const bool _flashOnPageTurnDefault = false;
  bool _flashOnPageTurn = _flashOnPageTurnDefault;
  bool get flashOnPageTurn => _flashOnPageTurn;

  static const String _gradualPageTurnsKey = "page_turning.gradual";
  static const bool _gradualPageTurnsDefault = false;
  bool _gradualPageTurns = _gradualPageTurnsDefault;
  bool get gradualPageTurns => _gradualPageTurns;

  PageTurningSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading page turning settings");
    _flashOnPageTurn =
        (await _repo.loadBool(_flashOnPageTurnKey)) ?? _flashOnPageTurnDefault;
    _gradualPageTurns =
        (await _repo.loadBool(_gradualPageTurnsKey)) ??
        _gradualPageTurnsDefault;
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting page turning settings");
    _flashOnPageTurn = _flashOnPageTurnDefault;
    _gradualPageTurns = _gradualPageTurnsDefault;
    notifyListeners();
    _repo.remove(_flashOnPageTurnKey);
    _repo.remove(_gradualPageTurnsKey);
  }

  set flashOnPageTurn(bool value) {
    if (value == _flashOnPageTurn) return;
    Log.debug("flash on page turn: $value");
    _flashOnPageTurn = value;
    notifyListeners();
    _repo.store(_flashOnPageTurnKey, _flashOnPageTurn);
  }

  set gradualPageTurns(bool value) {
    if (value == _gradualPageTurns) return;
    Log.debug("gradual page turns: $value");
    _gradualPageTurns = value;
    notifyListeners();
    _repo.store(_gradualPageTurnsKey, _gradualPageTurns);
  }
}
