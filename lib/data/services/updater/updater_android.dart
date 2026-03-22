/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/updater/updater.dart';

class AndroidUpdateFailedException {
  final PackageInstallerStatus _status;
  final String message;
  AndroidUpdateFailedException(this.message, this._status);

  @override
  String toString() {
    return "AndroidUpdateFailedException: ${_status.name}: $message";
  }
}

class UpdaterAndroid implements Updater {
  final deviceInfo = DeviceInfoPlugin();

  @override
  Future<String> generateDownloadFileName(Version version) async {
    try {
      final arch = await _getArchitecture();
      return "Sheetopia-$version-android-$arch.apk";
    } on Exception catch (e, st) {
      Log.error(
        "Failed to get system architecture. Defaulting to arm64v8",
        e: e,
        st: st,
      );
      return "arm64v8";
    }
  }

  @override
  Future<void> install(File downloadedFile) async {
    if (await _isMIUIDevice()) {
      final permissionGranted = await _requestInstallApkPermission();
      if (!permissionGranted) {
        throw AndroidUpdateFailedException(
          "User declined APK install permission",
          PackageInstallerStatus.failureAborted,
        );
      }
      return await _openApk(downloadedFile);
    } else {
      return await _installApk(downloadedFile);
    }
  }

  Future<void> _installApk(File downloadedFile) async {
    int? statusCode = await AndroidPackageInstaller.installApk(
      apkFilePath: downloadedFile.path,
    );
    if (statusCode != null) {
      final status = PackageInstallerStatus.byCode(statusCode);
      if (status == PackageInstallerStatus.success) {
        return;
      }
      throw AndroidUpdateFailedException("Failed to install APK", status);
    }
    throw AndroidUpdateFailedException(
      "Unknown APK install status, assuming failure",
      PackageInstallerStatus.unknown,
    );
  }

  Future<bool> _requestInstallApkPermission() async {
    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) {
      return true;
    } else {
      final newStatus = await Permission.requestInstallPackages.request();
      if (newStatus.isGranted) {
        return true;
      } else {
        return false;
      }
    }
  }

  Future<void> _openApk(File downloadedFile) async {
    final result = await OpenFile.open(
      downloadedFile.path,
      type: "application/vnd.android.package-archive",
    );
    if (result.type != ResultType.done) {
      throw AndroidUpdateFailedException(
        "Failed to open APK file",
        PackageInstallerStatus.failure,
      );
    }
  }

  Future<bool> _isMIUIDevice() async {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.manufacturer.toLowerCase() == "xiaomi";
  }

  Future<String> _getArchitecture() async {
    final androidInfo = await deviceInfo.androidInfo;
    final abis = androidInfo.supportedAbis;
    if (abis.contains("arm64-v8a")) {
      return "arm64v8";
    }
    if (abis.contains("armeabi-v7a")) {
      return "arm32v7";
    }
    if (abis.contains("x86_64")) {
      return "x64";
    }
    Log.warn("Couldn't find known ABI in list: $abis. Defaulting to arm64v8");
    return "arm64v8";
  }
}
