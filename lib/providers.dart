import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sheetopia/data/repositories/appimage/appimage_repository.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
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

  return [
    Provider.value(value: database),
    Provider.value(value: logRepository),
    Provider(create: (context) => KeyValueRepository(database: context.read())),
    Provider(
      create: (context) =>
          SettingsRepository(keyValueRepository: context.read()),
    ),
    Provider(create: (context) => GitHubService()),
    Provider(
      create: (context) =>
          VersionRepository(github: context.read(), keyValue: context.read()),
    ),
    ChangeNotifierProvider(
      create: (context) => VersionCheckerViewModel(
        keyValue: context.read(),
        versionRepo: context.read(),
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
    Provider(create: (context) => const ThumbnailService()),
    Provider(create: (context) => SyncService()),
    Provider(
      create: (context) => ScoresRepository(
        db: context.read(),
        thumbnailService: context.read(),
      ),
    ),
    Provider(
      create: (context) => SyncRepository(
        scoresRepo: context.read(),
        keyValue: context.read(),
        db: context.read(),
        syncService: context.read(),
        thumbnailService: context.read(),
      ),
      // sync should start immediately
      lazy: false,
    ),
    Provider(create: (context) => MidiRepository(), lazy: false),
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
  ];
}
