/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// Entry point of the screenshot build: the E2E driver build plus actions to
// import a library without the file picker, switch the theme and navigate.
// Never shipped.

import 'dart:convert';
import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/main.dart' as app;
import 'package:sheetopia/routing/router.dart';

import '../../test/app/main_e2e.dart';

Future<void> main() async {
  enableE2eDriver(
    extraActions: {
      'upload': _upload,
      'import': _import,
      'theme': _theme,
      'go': _go,
      'unfocus': _unfocus,
      'reset': _reset,
    },
  );
  await app.main();
}

BuildContext get _context => goRouter.routerDelegate.navigatorKey.currentContext!;

Future<File> _uploadFile(String name) async =>
    File(path.join((await getTemporaryDirectory()).path, 'sheetopia-screenshots', path.basename(name)));

/// Writes a file in base64 chunks (`append` for every chunk after the first),
/// the VM service connection limits the message size.
Future<Object?> _upload(Map<String, dynamic> args) async {
  final file = await _uploadFile(args['name'] as String);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(base64Decode(args['data'] as String), mode: args['append'] == true ? FileMode.append : FileMode.write);
  return {'path': file.path, 'size': await file.length()};
}

/// Imports an uploaded library ZIP through Settings > Import.
Future<Object?> _import(Map<String, dynamic> args) async {
  final repo = _context.read<ImportExportRepository>();
  final file = await _uploadFile(args['name'] as String);
  FileSelectorPlatform.instance = _UploadedFileSelector(file.path);
  final ok = await repo.import();
  await file.delete();
  return {'imported': ok};
}

Future<Object?> _theme(Map<String, dynamic> args) async {
  _context.read<SettingsRepository>().appearanceSettings.themeMode = ThemeMode.values.byName(args['mode'] as String);
  await SchedulerBinding.instance.endOfFrame;
  return {'theme': args['mode']};
}

Future<Object?> _go(Map<String, dynamic> args) async {
  goRouter.go(args['location'] as String);
  await SchedulerBinding.instance.endOfFrame;
  return {'route': goRouter.routerDelegate.currentConfiguration.uri.toString()};
}

/// Closes dialogs, sheets and menus and goes back to the library.
Future<Object?> _reset(Map<String, dynamic> args) async {
  goRouter.routerDelegate.navigatorKey.currentState!.popUntil((route) => route is! PopupRoute);
  goRouter.go('/');
  await SchedulerBinding.instance.endOfFrame;
  return {'route': goRouter.routerDelegate.currentConfiguration.uri.toString()};
}

Future<Object?> _unfocus(Map<String, dynamic> args) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SchedulerBinding.instance.endOfFrame;
  return {};
}

class _UploadedFileSelector extends FileSelectorPlatform {
  final String _path;

  _UploadedFileSelector(this._path);

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile(_path);
}
