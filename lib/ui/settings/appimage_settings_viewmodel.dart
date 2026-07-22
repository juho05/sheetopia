/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';

class AppImageSettingsViewModel extends ChangeNotifier {
  final AppImageRepository _repo;

  bool? _integrated;

  bool? get integrated => _integrated;

  AppImageSettingsViewModel({required AppImageRepository appImageRepository})
    : _repo = appImageRepository {
    _repo.isIntegrated().then((value) {
      _integrated = value;
      notifyListeners();
    });
  }

  Future<void> integrate() async {
    await _repo.integrate();
  }
}
