import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheetopia/data/services/database/genres_table.dart';
import 'package:sheetopia/data/services/database/instruments_table.dart';
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
  ],
)
class Database extends _$Database {
  Database([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement("PRAGMA foreign_keys = ON");
      await customStatement("PRAGMA journal_mode = WAL");
      await customStatement("PRAGMA busy_timeout = 5000");
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sheetopia_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  static const Uuid uuid = Uuid();

  String newId() {
    return uuid.v4();
  }
}
