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
