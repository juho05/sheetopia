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
  double _imageOpacity = 0;
  double get imageOpacity => _imageOpacity;

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

  void update({
    required Score score,
    required int width,
    required int height,
  }) async {
    _score = score;
    _width = width;
    _height = height;
    _imageOpacity = 0;
    _image = null;
    notifyListeners();
    _load();
  }

  void updateSize({required int width, required int height}) async {
    _width = width;
    _height = height;
    notifyListeners();
    _load(keepOldImageDuringLoad: true);
  }

  Future<void> _load({bool keepOldImageDuringLoad = false}) async {
    if (!keepOldImageDuringLoad) {
      _imageOpacity = 0;
      _image = null;
      notifyListeners();
    }

    final path = await _service.getThumbnail(
      _score,
      width: _width,
      height: _height,
    );
    if (path == null) {
      _imageOpacity = 0;
      _image = null;
      notifyListeners();
      return;
    }
    _image = File(path);
    _imageOpacity = 1;
    notifyListeners();
  }
}
