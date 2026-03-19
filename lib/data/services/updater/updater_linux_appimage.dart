import 'dart:io';

import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/updater/updater.dart';

class UpdaterLinuxAppImage implements Updater {
  @override
  Future<String> generateDownloadFileName(Version version) async =>
      "Sheetopia-$version-linux-x86-64.AppImage";

  @override
  Future<void> install(File downloadedFile) async {
    // delete existing file first to prevent "Text file busy" error
    await AppImageRepository.appImageFile.delete();
    await downloadedFile.copy(AppImageRepository.appImageFile.path);

    try {
      await Process.run("chmod", [
        "+x",
        AppImageRepository.appImageFile.path,
      ], runInShell: true);
    } on Exception catch (e, st) {
      Log.error("Failed to make updated AppImage executable", e: e, st: st);
    }
  }
}
