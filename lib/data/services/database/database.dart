import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheetopia/data/services/database/deleted_scores_table.dart';
import 'package:sheetopia/data/services/database/deleted_tags_table.dart';
import 'package:sheetopia/data/services/database/genres_table.dart';
import 'package:sheetopia/data/services/database/instruments_table.dart';
import 'package:sheetopia/data/services/database/key_value_table.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ScoresTable,
    GenresTable,
    InstrumentsTable,
    TagsTable,
    ScoreTagsTable,
    KeyValueTable,
    DeletedTagsTable,
    DeletedScoresTable,
  ],
)
class Database extends _$Database {
  Database([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement("PRAGMA foreign_keys = ON");
      await customStatement("PRAGMA journal_mode = WAL");
      await customStatement("PRAGMA busy_timeout = 5000");
    },
  );

  static QueryExecutor _openConnection() {
    var db = driftDatabase(
      name: 'sheetopia_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
    // db = db.interceptWith(LogInterceptor());
    return db;
  }

  static const Uuid uuid = Uuid();

  String newId() {
    return uuid.v4();
  }
}
