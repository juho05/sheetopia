/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/auto_update/auto_update_repository.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/repositories/themeManager/theme_manager.dart';
import 'package:sheetopia/data/repositories/version/version_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/github/github.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/integrate_appimage_viewmodel.dart';
import 'package:sheetopia/version_checker_viewmodel.dart';

Future<List<SingleChildWidget>> createProviders({
  required LogRepository logRepository,
}) async {
  final database = Database();

  await logRepository.enablePersistence(database);

  final KeyValueRepository keyValue = KeyValueRepository(database: database);
  final SettingsRepository settings = SettingsRepository(
    keyValueRepository: keyValue,
  );
  await settings.load();

  return [
    Provider.value(value: database),
    Provider.value(value: logRepository),
    Provider.value(value: keyValue),
    Provider.value(value: settings),
    Provider(create: (context) => GitHubService()),
    Provider(
      create: (context) =>
          VersionRepository(github: context.read(), keyValue: context.read()),
    ),
    ChangeNotifierProvider(
      create: (context) => VersionCheckerViewModel(
        keyValue: context.read(),
        versionRepo: context.read(),
        settings: context.read(),
      )..check(),
    ),
    ChangeNotifierProvider(
      create: (context) => ThemeManager(
        keyValue: context.read(),
        appearanceSettings: context
            .read<SettingsRepository>()
            .appearanceSettings,
      ),
    ),
    Provider(create: (context) => ThumbnailService()),
    Provider(create: (context) => SyncService()),
    Provider(
      create: (context) => ScoresRepository(
        db: context.read(),
        thumbnailService: context.read(),
      ),
    ),
    Provider(
      create: (context) =>
          SetlistsRepository(db: context.read(), scoresRepo: context.read()),
      lazy: false,
    ),
    Provider(
      create: (context) => SyncRepository(
        scoresRepo: context.read(),
        setlistsRepo: context.read(),
        keyValue: context.read(),
        db: context.read(),
        syncService: context.read(),
        thumbnailService: context.read(),
      ),
      // sync should start immediately
      lazy: false,
    ),
    ChangeNotifierProvider(
      create: (context) => ImportExportRepository(
        scoresRepo: context.read(),
        setlistsRepo: context.read(),
        syncRepo: context.read(),
        thumbnailService: context.read(),
        db: context.read(),
      ),
    ),
    Provider(
      create: (context) => MidiRepository(keyValue: context.read()),
      lazy: false,
    ),
    if (AppImageRepository.isAppImage)
      Provider(
        create: (context) => AppImageRepository(keyValue: context.read()),
      ),
    if (AppImageRepository.isAppImage)
      ChangeNotifierProvider(
        create: (context) =>
            IntegrateAppImageViewModel(appImageRepository: context.read())
              ..check(),
      ),
    if (AutoUpdateRepository.autoUpdatesSupported)
      ChangeNotifierProvider(
        create: (context) => AutoUpdateRepository(
          versionRepository: context.read(),
          github: context.read(),
        ),
      ),
  ];
}
