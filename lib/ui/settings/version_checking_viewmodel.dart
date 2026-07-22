/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/settings/version_checking.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';

class VersionCheckingViewModel extends ChangeNotifier {
  final VersionCheckingSettings _settings;
  final VersionRepository _repository;

  bool _enabled = true;

  bool get enabled => _enabled;

  bool _checking = false;

  bool get checking => _checking;

  VersionCheckingViewModel({
    required VersionCheckingSettings settings,
    required VersionRepository repository,
  }) : _repository = repository,
       _settings = settings {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    _enabled = _settings.enabled;
    notifyListeners();
  }

  void updateEnabled(bool enabled) {
    _settings.enabled = enabled;
  }

  Future<({Version current, Version? latest})> check() async {
    _checking = true;
    notifyListeners();
    try {
      final current = await VersionRepository.getCurrentVersion();
      final latest = await _repository.getLatestVersion(force: true);
      return (current: current, latest: latest);
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
