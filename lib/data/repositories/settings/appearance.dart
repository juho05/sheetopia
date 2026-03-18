import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';

class AppearanceSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _themeModeKey = "appearance.theme_mode";
  static const ThemeMode _themeModeDefault = ThemeMode.system;
  ThemeMode _themeMode = _themeModeDefault;
  ThemeMode get themeMode => _themeMode;

  AppearanceSettings({required KeyValueRepository keyValueRepository})
    : _repo = keyValueRepository;

  Future<void> load() async {
    Log.trace("loading appearance settings");
    _themeMode = ThemeMode.values.byName(
      (await _repo.loadString(_themeModeKey)) ?? _themeModeDefault.name,
    );
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting appearance settings");
    _themeMode = _themeModeDefault;
    notifyListeners();
    _repo.remove(_themeModeKey);
  }

  set themeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    Log.debug("theme mode: ${mode.name}");
    _themeMode = mode;
    notifyListeners();
    _repo.store(_themeModeKey, _themeMode.name);
  }
}
