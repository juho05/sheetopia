/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';

class ThumbnailService {
  static const int _maxCachedPaths = 2000;

  ThumbnailService();

  final Map<String, String> _pathCache = {};
  Directory? _cacheDir;

  Future<void> invalidateThumbnails(Iterable<String> scoreIds) async {
    for (final scoreId in scoreIds) {
      _pathCache.removeWhere((key, _) => key.startsWith("$scoreId/"));
      try {
        final dir = await _scoreDir(scoreId);
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Already resolved thumbnail path, without touching the file system.
  String? cachedThumbnail(
    Score score, {
    required int width,
    required int height,
  }) {
    if (score.file == null) return null;
    return _pathCache[_cacheKey(score.id, width: width, height: height)];
  }

  Future<String?> getThumbnail(
    Score score, {
    required int width,
    required int height,
  }) async {
    if (score.file == null) return null;
    final key = _cacheKey(score.id, width: width, height: height);
    final cached = _pathCache[key];
    if (cached != null) return cached;

    final path = await _thumbnailPath(score.id, width: width, height: height);
    if (await File(path).exists()) {
      _cachePath(key, path);
      return path;
    }
    final generated = switch (score.fileType) {
      FileType.pdf => await _generateThumbnailPDF(
        score,
        width: width,
        height: height,
      ),
    };
    if (generated != null) _cachePath(key, generated);
    return generated;
  }

  String _cacheKey(String scoreId, {required int width, required int height}) =>
      "$scoreId/${width}x$height";

  void _cachePath(String key, String path) {
    if (_pathCache.length >= _maxCachedPaths) {
      _pathCache.remove(_pathCache.keys.first);
    }
    _pathCache[key] = path;
  }

  Future<String?> _generateThumbnailPDF(
    Score score, {
    required int width,
    required int height,
  }) async {
    final pdf = await PdfDocument.openFile(
      score.file!.path,
      useProgressiveLoading: true,
    );
    if (pdf.pages.isEmpty) return null;
    PdfImage? pdfImage;
    try {
      final page = pdf.pages.first;
      final fullHeight = width * (page.height / page.width);
      final actualHeight = min(height, fullHeight.floor());

      bool renderHigherResolution = width < 500;

      pdfImage = await page.render(
        x: 0,
        y: 0,
        fullWidth: width.toDouble() * (renderHigherResolution ? 2 : 1),
        fullHeight: fullHeight * (renderHigherResolution ? 2 : 1),
        width: width * (renderHigherResolution ? 2 : 1),
        height: actualHeight * (renderHigherResolution ? 2 : 1),
      );
      if (pdfImage == null) return null;

      final path = await _thumbnailPath(
        score.id,
        width: width,
        height: height,
        create: true,
      );

      await compute((pdfImage) async {
        var image = img.Image.fromBytes(
          width: pdfImage.width,
          height: pdfImage.height,
          bytes: pdfImage.pixels.buffer,
          format: img.Format.uint8,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        );
        if (renderHigherResolution) {
          image = img.resize(
            image,
            width: width,
            height: height,
            interpolation: img.Interpolation.average,
          );
        }
        await img.encodeJpgFile(path, image, quality: 90);
      }, pdfImage);

      return path;
    } finally {
      pdfImage?.dispose();
      await pdf.dispose();
    }
  }

  Future<Directory> _scoreDir(String scoreId) async {
    final cacheDir = _cacheDir ??= Directory(
      path.join((await getApplicationCacheDirectory()).path, "thumbnails"),
    );
    return Directory(path.join(cacheDir.path, scoreId));
  }

  Future<String> _thumbnailPath(
    String scoreId, {
    required int width,
    required int height,
    bool create = false,
  }) async {
    final scoreDir = await _scoreDir(scoreId);
    if (create && !await scoreDir.exists()) {
      await scoreDir.create(recursive: true);
    }
    return path.join(scoreDir.path, "${width}x$height.jpg");
  }
}
