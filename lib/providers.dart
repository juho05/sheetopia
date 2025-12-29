import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

Future<List<SingleChildWidget>> createProviders() async {
  final database = Database();

  return [
    Provider.value(value: database),
    Provider(create: (context) => KeyValueRepository(database: context.read())),
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
      ),
      // sync should start immediately
      lazy: false,
    ),
  ];
}
