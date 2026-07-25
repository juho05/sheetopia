/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

class ThumbnailViewModel extends ChangeNotifier {
  final ThumbnailService _service;

  File? _image;
  File? get image => _image;

  Score _score;
  int _width;
  int _height;

  ThumbnailViewModel({
    required ThumbnailService service,
    required Score score,
    required int width,
    required int height,
  }) : _service = service,
       _score = score,
       _width = width,
       _height = height {
    _load();
  }

  void update({required Score score, required int width, required int height}) {
    _score = score;
    _width = width;
    _height = height;
    _load();
  }

  void updateSize({required int width, required int height}) {
    _width = width;
    _height = height;
    _load(keepOldImageDuringLoad: true);
  }

  int _loadId = 0;

  Future<void> _load({bool keepOldImageDuringLoad = false}) async {
    final loadId = ++_loadId;

    final cached = _service.cachedThumbnail(
      _score,
      width: _width,
      height: _height,
    );
    if (cached != null) {
      _image = File(cached);
      notifyListeners();
      return;
    }

    if (!keepOldImageDuringLoad) {
      _image = null;
      notifyListeners();
    }

    final path = await _service.getThumbnail(
      _score,
      width: _width,
      height: _height,
    );
    if (loadId != _loadId) return;
    _image = path == null ? null : File(path);
    notifyListeners();
  }
}
