// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v14.dart' as v14;
import 'generated/schema_v15.dart' as v15;
import 'generated/schema_v16.dart' as v16;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = Database(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldScoresData = <v1.ScoresData>[];
    final expectedNewScoresData = <v2.ScoresData>[];

    final oldGenresData = <v1.GenresData>[];
    final expectedNewGenresData = <v2.GenresData>[];

    final oldInstrumentsData = <v1.InstrumentsData>[];
    final expectedNewInstrumentsData = <v2.InstrumentsData>[];

    final oldTagsData = <v1.TagsData>[];
    final expectedNewTagsData = <v2.TagsData>[];

    final oldScoreTagsData = <v1.ScoreTagsData>[];
    final expectedNewScoreTagsData = <v2.ScoreTagsData>[];

    final oldKeyValueData = <v1.KeyValueData>[];
    final expectedNewKeyValueData = <v2.KeyValueData>[];

    final oldDeletedTagsData = <v1.DeletedTagsData>[];
    final expectedNewDeletedTagsData = <v2.DeletedTagsData>[];

    final oldDeletedScoresData = <v1.DeletedScoresData>[];
    final expectedNewDeletedScoresData = <v2.DeletedScoresData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: Database.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.scores, oldScoresData);
        batch.insertAll(oldDb.genres, oldGenresData);
        batch.insertAll(oldDb.instruments, oldInstrumentsData);
        batch.insertAll(oldDb.tags, oldTagsData);
        batch.insertAll(oldDb.scoreTags, oldScoreTagsData);
        batch.insertAll(oldDb.keyValue, oldKeyValueData);
        batch.insertAll(oldDb.deletedTags, oldDeletedTagsData);
        batch.insertAll(oldDb.deletedScores, oldDeletedScoresData);
      },
      validateItems: (newDb) async {
        expect(expectedNewScoresData, await newDb.select(newDb.scores).get());
        expect(expectedNewGenresData, await newDb.select(newDb.genres).get());
        expect(
          expectedNewInstrumentsData,
          await newDb.select(newDb.instruments).get(),
        );
        expect(expectedNewTagsData, await newDb.select(newDb.tags).get());
        expect(
          expectedNewScoreTagsData,
          await newDb.select(newDb.scoreTags).get(),
        );
        expect(
          expectedNewKeyValueData,
          await newDb.select(newDb.keyValue).get(),
        );
        expect(
          expectedNewDeletedTagsData,
          await newDb.select(newDb.deletedTags).get(),
        );
        expect(
          expectedNewDeletedScoresData,
          await newDb.select(newDb.deletedScores).get(),
        );
      },
    );
  });

  test(
    "migration from v15 to v16 marks existing scores as just inserted",
    () async {
      const old = "2026-01-01T00:00:00.000Z";
      final before = DateTime.now().toUtc();

      await verifier.testWithDataIntegrity(
        oldVersion: 15,
        newVersion: 16,
        createOld: v15.DatabaseAtV15.new,
        createNew: v16.DatabaseAtV16.new,
        openTestedDatabase: Database.new,
        createItems: (batch, oldDb) {
          batch.customStatement(
            "INSERT INTO scores (id, title, search_text, last_opened, "
            "metadata_updated_at, file_updated_at, file_downloaded, file_type, "
            "type) VALUES ('score', 'Etude', ' etude ', '$old', '$old', "
            "'$old', 1, 'pdf', 'exercise')",
          );
        },
        validateItems: (newDb) async {
          final score = await newDb.select(newDb.scores).getSingle();
          expect(score.title, "Etude");
          expect(score.type, "exercise");
          expect(score.metadataUpdatedAt, old);
          expect(score.recentTime, old);
          expect(
            DateTime.parse(score.insertedAt).isBefore(before),
            isFalse,
            reason: "the sweep waits 3h before touching migrated scores",
          );
        },
      );
    },
  );

  // tester carry over, remove later
  test(
    "migration from v14 to v15 turns session entries into records",
    () async {
      const updated = "2026-09-20T08:00:00.000Z";
      const older = "2026-09-19T07:00:00.000Z";
      const latest = "2026-09-20T07:00:00.000Z";
      const adHoc = "2026-09-21T10:00:00.000Z";

      await verifier.testWithDataIntegrity(
        oldVersion: 14,
        newVersion: 15,
        createOld: v14.DatabaseAtV14.new,
        createNew: v15.DatabaseAtV15.new,
        openTestedDatabase: Database.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.exercises, [
            const v14.ExercisesData(
              id: "exercise",
              name: "Scales",
              updatedAt: updated,
              uploaded: 1,
            ),
          ]);
          batch.insertAll(oldDb.practiceRoutines, [
            const v14.PracticeRoutinesData(
              id: "routine",
              name: "Morning",
              updatedAt: updated,
              uploaded: 1,
            ),
          ]);
          batch.insertAll(oldDb.practiceSessions, [
            const v14.PracticeSessionsData(
              id: "older",
              startedAt: older,
              routine: "routine",
              updatedAt: updated,
              uploaded: 1,
            ),
            const v14.PracticeSessionsData(
              id: "latest",
              startedAt: latest,
              routine: "routine",
              updatedAt: updated,
              uploaded: 1,
            ),
            const v14.PracticeSessionsData(
              id: "ad-hoc",
              startedAt: adHoc,
              updatedAt: updated,
              uploaded: 1,
            ),
          ]);
          batch.insertAll(oldDb.practiceSessionEntries, [
            const v14.PracticeSessionEntriesData(
              id: "first",
              session: "latest",
              exercise: "exercise",
              routineEntry: "entry-a",
              startedAt: latest,
              duration: 60000,
            ),
            const v14.PracticeSessionEntriesData(
              id: "second",
              session: "latest",
              exercise: "exercise",
              routineEntry: "entry-b",
              startedAt: latest,
              duration: 120000,
            ),
            const v14.PracticeSessionEntriesData(
              id: "alone",
              session: "ad-hoc",
              exercise: "exercise",
              startedAt: adHoc,
              duration: 30000,
            ),
          ]);
        },
        validateItems: (newDb) async {
          final records = await (newDb.select(
            newDb.practiceRecords,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
          expect(records, const [
            v15.PracticeRecordsData(
              id: "alone",
              exercise: "exercise",
              startedAt: adHoc,
              duration: 30000,
              updatedAt: updated,
              uploaded: 0,
            ),
            v15.PracticeRecordsData(
              id: "first",
              exercise: "exercise",
              routine: "routine",
              routineEntry: "entry-a",
              startedAt: latest,
              duration: 60000,
              updatedAt: updated,
              uploaded: 0,
            ),
            v15.PracticeRecordsData(
              id: "second",
              exercise: "exercise",
              routine: "routine",
              routineEntry: "entry-b",
              startedAt: latest,
              duration: 120000,
              updatedAt: updated,
              uploaded: 0,
            ),
          ]);

          final routine = await newDb
              .select(newDb.practiceRoutines)
              .getSingle();
          expect(routine.progressResetAt, latest);
          expect(routine.uploaded, 1, reason: "the derived reset stays local");
          final exercise = await newDb.select(newDb.exercises).getSingle();
          expect(exercise.progressResetAt, adHoc);
        },
      );
    },
  );
}
