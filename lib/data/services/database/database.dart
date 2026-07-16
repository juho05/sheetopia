/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sheetopia/data/services/database/deleted_scores_table.dart';
import 'package:sheetopia/data/services/database/deleted_tags_table.dart';
import 'package:sheetopia/data/services/database/genres_table.dart';
import 'package:sheetopia/data/services/database/instruments_table.dart';
import 'package:sheetopia/data/services/database/key_value_table.dart';
import 'package:sheetopia/data/services/database/log_interceptor.dart';
import 'package:sheetopia/data/services/database/log_level_converter.dart';
import 'package:sheetopia/data/services/database/log_message.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:uuid/uuid.dart';

import 'database.steps.dart';

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
    LogMessageTable,
  ],
)
class Database extends _$Database {
  Database([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      await customStatement("PRAGMA foreign_keys = OFF");
      await transaction(
        () async => m.runMigrationSteps(
          from: from,
          to: to,
          steps: migrationSteps(
            from1To2: (m, schema) async {
              await m.addColumn(schema.scores, schema.scores.notes);
            },
            from2To3: (m, schema) async {
              await m.createTable(schema.logMessage);
            },
            from3To4: (m, schema) async {
              await m.alterTable(
                TableMigration(
                  schema.scores,
                  newColumns: [
                    schema.scores.lastOpened,
                    schema.scores.recentTime,
                  ],
                  columnTransformer: {
                    schema.scores.lastOpened: const CustomExpression(
                      "MAX(metadata_updated_at,file_updated_at)",
                    ),
                  },
                ),
              );
              await m.createIndex(
                Index(
                  'recent_time_index',
                  'CREATE INDEX recent_time_index ON scores (recent_time)',
                ),
              );
            },
            from4To5: (m, schema) async {
              await m.createTable(schema.annotations);
            },
            from5To6: (m, schema) async {
              await m.addColumn(schema.scores, schema.scores.annotations);
              await m.deleteTable('annotations');
            },
          ),
        ),
      );
      if (kDebugMode) {
        // Fail if the migration broke foreign keys
        final wrongForeignKeys = await customSelect(
          'PRAGMA foreign_key_check',
        ).get();
        assert(
          wrongForeignKeys.isEmpty,
          '${wrongForeignKeys.map((e) => e.data)}',
        );
      }

      await customStatement("PRAGMA foreign_keys = ON");
    },
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
    db = db.interceptWith(LogInterceptor());
    return db;
  }

  static const Uuid uuid = Uuid();

  String newId() {
    return uuid.v4();
  }
}
