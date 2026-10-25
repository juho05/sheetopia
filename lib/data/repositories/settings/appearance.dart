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

enum CardSubtitle {
  composer("Composer"),
  arranger("Arranger"),
  composerAndArranger("Composer and arranger");

  final String label;

  const CardSubtitle(this.label);
}

enum CardBadges {
  instruments("Instruments"),
  genres("Genres"),
  none("None");

  final String label;

  const CardBadges(this.label);
}

class AppearanceSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _themeModeKey = "appearance.theme_mode";
  static const ThemeMode _themeModeDefault = ThemeMode.system;
  ThemeMode _themeMode = _themeModeDefault;
  ThemeMode get themeMode => _themeMode;

  static const String _cardSubtitleKey = "appearance.card_subtitle";
  static const CardSubtitle _cardSubtitleDefault = CardSubtitle.composer;
  CardSubtitle _cardSubtitle = _cardSubtitleDefault;
  CardSubtitle get cardSubtitle => _cardSubtitle;

  static const String _cardBadgesKey = "appearance.card_badges";
  static const CardBadges _cardBadgesDefault = CardBadges.instruments;
  CardBadges _cardBadges = _cardBadgesDefault;
  CardBadges get cardBadges => _cardBadges;

  static const String _cardDifficultyKey = "appearance.card_difficulty";
  static const bool _cardDifficultyDefault = false;
  bool _cardDifficulty = _cardDifficultyDefault;
  bool get cardDifficulty => _cardDifficulty;

  AppearanceSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading appearance settings");
    _themeMode = ThemeMode.values.byName(
      (await _repo.loadString(_themeModeKey)) ?? _themeModeDefault.name,
    );
    _cardSubtitle =
        CardSubtitle.values.asNameMap()[await _repo.loadString(
          _cardSubtitleKey,
        )] ??
        _cardSubtitleDefault;
    _cardBadges =
        CardBadges.values.asNameMap()[await _repo.loadString(_cardBadgesKey)] ??
        _cardBadgesDefault;
    _cardDifficulty =
        (await _repo.loadBool(_cardDifficultyKey)) ?? _cardDifficultyDefault;
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting appearance settings");
    _themeMode = _themeModeDefault;
    _cardSubtitle = _cardSubtitleDefault;
    _cardBadges = _cardBadgesDefault;
    _cardDifficulty = _cardDifficultyDefault;
    notifyListeners();
    _repo.remove(_themeModeKey);
    _repo.remove(_cardSubtitleKey);
    _repo.remove(_cardBadgesKey);
    _repo.remove(_cardDifficultyKey);
  }

  set themeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    Log.debug("theme mode: ${mode.name}");
    _themeMode = mode;
    notifyListeners();
    _repo.store(_themeModeKey, _themeMode.name);
  }

  set cardSubtitle(CardSubtitle value) {
    if (value == _cardSubtitle) return;
    Log.debug("card subtitle: ${value.name}");
    _cardSubtitle = value;
    notifyListeners();
    _repo.store(_cardSubtitleKey, value.name);
  }

  set cardBadges(CardBadges value) {
    if (value == _cardBadges) return;
    Log.debug("card badges: ${value.name}");
    _cardBadges = value;
    notifyListeners();
    _repo.store(_cardBadgesKey, value.name);
  }

  set cardDifficulty(bool value) {
    if (value == _cardDifficulty) return;
    Log.debug("card difficulty: $value");
    _cardDifficulty = value;
    notifyListeners();
    _repo.store(_cardDifficultyKey, value);
  }
}
