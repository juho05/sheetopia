/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/settings/appearance.dart';
import 'package:sheetopia/data/repositories/settings/logging.dart';
import 'package:sheetopia/data/repositories/settings/version_checking.dart';

class SettingsRepository {
  final LoggingSettings logging;
  final AppearanceSettings appearanceSettings;
  final VersionCheckingSettings versionChecking;

  SettingsRepository({required KeyValueRepository keyValueRepository})
    : logging = LoggingSettings(keyValueRepository: keyValueRepository),
      appearanceSettings = AppearanceSettings(
        keyValueRepository: keyValueRepository,
      ),
      versionChecking = VersionCheckingSettings(
        keyValueRepository: keyValueRepository,
      );

  Future<void> load() async {
    Log.debug("loading settings from db");
    await logging.load();
    await Future.wait([appearanceSettings.load(), versionChecking.load()]);
  }

  void dispose() {
    appearanceSettings.dispose();
    versionChecking.dispose();
    logging.dispose();
  }
}
