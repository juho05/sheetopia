/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';
import 'package:sheetopia/data/services/github/github.dart';
import 'package:sheetopia/data/services/updater/updater.dart';
import 'package:sheetopia/data/services/updater/updater_android.dart';
import 'package:sheetopia/data/services/updater/updater_linux_appimage.dart';
import 'package:sheetopia/data/services/updater/updater_macos.dart';
import 'package:sheetopia/data/services/updater/updater_windows.dart';

enum AutoUpdateStatus {
  initial,
  checkingVersion,
  downloading,
  installing,
  success,
  failure,
}

class AutoUpdateRepository extends ChangeNotifier {
  final VersionRepository _versionRepository;
  final GitHubService _github;
  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      // timeout between byte events not total transfer
      receiveTimeout: const Duration(seconds: 5),
      responseType: ResponseType.stream,
    ),
  );

  static bool get autoUpdatesSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isWindows ||
          Platform.isMacOS ||
          AppImageRepository.isAppImage) &&
      (!const bool.hasEnvironment("VERSION_CHECK") ||
          const bool.fromEnvironment("VERSION_CHECK"));

  late final Updater _updater;

  AutoUpdateStatus _status = AutoUpdateStatus.initial;
  AutoUpdateStatus get status => _status;

  final BehaviorSubject<double> _downloadProgress = BehaviorSubject.seeded(0);
  ValueStream<double> get downloadProgress => _downloadProgress.stream;

  AutoUpdateRepository({
    required VersionRepository versionRepository,
    required GitHubService github,
  }) : _versionRepository = versionRepository,
       _github = github {
    if (Platform.isAndroid) {
      Log.debug("update platform: Android");
      _updater = UpdaterAndroid();
    } else if (Platform.isWindows) {
      Log.debug("update platform: Windows");
      _updater = UpdaterWindows();
    } else if (Platform.isMacOS) {
      Log.debug("update platform: macOS");
      _updater = UpdaterMacOS();
    } else if (AppImageRepository.isAppImage) {
      Log.debug("update platform: Linux (AppImage)");
      _updater = UpdaterLinuxAppImage();
    } else {
      throw UnimplementedError(
        "auto updates are not supported on this platform",
      );
    }
  }

  Future<void> update() async {
    if (status != AutoUpdateStatus.initial &&
        status != AutoUpdateStatus.failure) {
      Log.warn("Cannot start auto update when it's already running.");
      return;
    }

    Log.info("Performing auto update...");

    _status = AutoUpdateStatus.checkingVersion;
    notifyListeners();

    try {
      final latestVersionTag = await _versionRepository.getLatestVersionTag(
        force: true,
      );
      if (latestVersionTag == null) {
        _status = AutoUpdateStatus.initial;
        notifyListeners();
        return;
      }
      final latestVersion = Version.parse(latestVersionTag);

      final currentVersion = await VersionRepository.getCurrentVersion();
      if (currentVersion >= latestVersion) {
        _status = AutoUpdateStatus.initial;
        notifyListeners();
        return;
      }

      final file = await _download(latestVersionTag);

      Log.debug("Installing ${file.path}...");
      _status = AutoUpdateStatus.installing;
      notifyListeners();

      try {
        await _updater.install(file);
      } finally {
        if (await file.exists()) {
          Log.debug("Removing installer file ${file.path}...");
          await file.delete();
        }
      }

      Log.info("Auto update successful!");
      _status = AutoUpdateStatus.success;
      notifyListeners();
    } on Exception catch (e, st) {
      Log.error("Auto update failed", e: e, st: st);
      _status = AutoUpdateStatus.failure;
      notifyListeners();
      return;
    }
  }

  Future<File> _download(String tag) async {
    final downloadFileName = await _updater.generateDownloadFileName(
      Version.parse(tag),
    );

    final uri = _github.generateReleaseDownloadLink(downloadFileName, tag);

    Log.debug("Downloading $uri...");

    _downloadProgress.add(0);
    _status = AutoUpdateStatus.downloading;
    notifyListeners();

    final targetDir = Directory(
      path.join(
        (await getTemporaryDirectory()).absolute.path,
        "auto_update_downloads",
      ),
    );

    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    final outputFile = File(
      path.join(targetDir.path, downloadFileName),
    ).absolute;

    await _dio.downloadUri(
      uri,
      outputFile.path,
      options: Options(
        headers: {
          "User-Agent":
              "Sheetopia v${await VersionRepository.getCurrentVersion()}",
        },
      ),
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        _downloadProgress.add(received / total);
      },
    );

    return outputFile;
  }
}
