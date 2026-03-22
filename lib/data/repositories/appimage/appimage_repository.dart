/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';

class AppImageRepository {
  final KeyValueRepository _keyValue;
  static const integrationDisabledKey = "integrate_appimage_disabled";

  final _desktopFileDirPath = path.join(
    Platform.environment["HOME"] ?? "~",
    ".local",
    "share",
    "applications",
  );

  AppImageRepository({required KeyValueRepository keyValue})
    : _keyValue = keyValue;

  static bool get isAppImage {
    return !kIsWeb &&
        Platform.isLinux &&
        Platform.environment.containsKey("APPIMAGE");
  }

  static File? _overrideAppImageFile;
  static File get appImageFile =>
      _overrideAppImageFile ?? File(Platform.environment["APPIMAGE"]!).absolute;

  Future<bool> shouldIntegrate() async {
    if (!isAppImage) {
      Log.trace("Skipping AppImage integration check: not an AppImage");
      return false;
    }

    if (Platform.environment["SHEETOPIA_DISABLE_APPIMAGE_INTEGRATION"] == "1") {
      Log.trace(
        "Skipping AppImage integration check: disabled by env variable",
      );
      return false;
    }

    final currentVersion = await VersionRepository.getCurrentVersion();

    final disabled = await _keyValue.loadObject(
      integrationDisabledKey,
      Version.fromJson,
    );
    if (disabled != null && disabled == currentVersion) {
      Log.debug("AppImage integration is disabled for version $disabled");
      return false;
    }

    if (await _isIntegrated()) {
      return false;
    }

    return true;
  }

  Future<void> integrate() async {
    Log.debug("Integrating AppImage into system...");
    final iconDir = await getApplicationSupportDirectory();

    Log.trace("Copying icon file...");
    final iconBytes = await rootBundle.load("assets/icon/sheetopia-circle.png");
    await File(
      path.join(iconDir.path, "sheetopia.png"),
    ).writeAsBytes(Uint8List.sublistView(iconBytes));

    final appImageDir = path.join(
      Platform.environment["HOME"] ?? "~",
      ".local",
      "bin",
    );
    final appImagePath = path.join(appImageDir, "sheetopia");

    await Directory(appImageDir).create(recursive: true);
    Log.trace("Moving AppImage...");
    _overrideAppImageFile = (await appImageFile.rename(appImagePath)).absolute;

    try {
      Log.trace("Ensuring AppImage is executable...");
      await Process.run("chmod", ["+x", appImagePath]);
    } catch (e, st) {
      Log.warn(
        "Failed to ensure that the integrated AppImage is executable",
        e: e,
        st: st,
      );
    }

    final desktopFile = await File(
      path.join(_desktopFileDirPath, "de.julianh.sheetopia.desktop"),
    ).create(recursive: true);
    Log.trace("Creating desktop file...");
    desktopFile.writeAsString("""[Desktop Entry]
Icon=${path.join(iconDir.path, "sheetopia.png")}
Exec=$appImagePath
Type=Application
Categories=Multimedia
Name=Sheetopia
StartupWMClass=de.julianh.sheetopia
Terminal=false
StartupNotify=true
""", flush: true);

    try {
      Log.trace("Updating desktop database...");
      Process.run("update-desktop-database", [_desktopFileDirPath]);
    } catch (e, st) {
      Log.debug(
        "Failed to update desktop database, update-desktop-database is probably not installed",
        e: e,
        st: st,
      );
    }

    await _keyValue.remove(integrationDisabledKey);

    Log.info("Successfully integrated AppImage into system!");
  }

  Future<void> disableIntegration() async {
    final version = await VersionRepository.getCurrentVersion();
    await _keyValue.store(integrationDisabledKey, version);
    Log.debug("User disabled AppImage integration for version $version");
  }

  Future<bool> _isIntegrated() async {
    Log.trace("The current AppImage path is: $appImageFile");

    final desiredAppImageFile = File(
      path.join(
        Platform.environment["HOME"] ?? "~",
        ".local",
        "bin",
        "sheetopia",
      ),
    );

    if (!await appImageFile.exists()) {
      Log.error("APPIMAGE environment variable does not point to a valid file");
      return true;
    }

    if (!await desiredAppImageFile.exists()) {
      Log.debug(
        "AppImage is not integrated because there is no AppImage at the desired system path",
      );
      return false;
    }

    final integrated = path.equals(appImageFile.path, desiredAppImageFile.path);

    if (integrated) {
      Log.debug("AppImage already integrated");
    } else {
      Log.debug(
        "AppImage not integrated because the current AppImage is not at the correct location",
      );
    }

    return integrated;
  }
}
