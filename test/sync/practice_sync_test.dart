/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/sync/models/exercise_categories.dart';
import 'package:sheetopia/data/services/sync/models/exercise_metadata.dart';
import 'package:sheetopia/data/services/sync/models/exercises.dart';
import 'package:sheetopia/data/services/sync/models/practice_routines.dart';
import 'package:sheetopia/data/services/sync/models/practice_sessions.dart';
import 'package:sheetopia/data/services/sync/models/server_info.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

class _InMemoryEncryptedStorage implements EncryptedStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

typedef _Upload = ({String id, DateTime? writtenAt});

class _FakeSyncService extends SyncService {
  String apiVersion = "0.4.0";
  DateTime syncTime = DateTime.utc(2026, 9, 2, 16);

  List<ExerciseCategoryModel> categories = [];
  List<ExerciseModel> exercises = [];
  List<PracticeRoutineModel> routines = [];
  List<PracticeSessionModel> sessions = [];

  List<RemotelyDeleted> deletedTags = [];
  List<RemotelyDeleted> deletedCategories = [];
  List<RemotelyDeleted> deletedExercises = [];
  List<RemotelyDeleted> deletedRoutines = [];
  List<RemotelyDeleted> deletedSessions = [];

  final uploadedCategories = <_Upload>[];
  final uploadedExercises = <_Upload>[];
  final uploadedRoutines = <_Upload>[];
  final uploadedSessions = <_Upload>[];

  final uploadedExerciseTagIds = <String, List<String>>{};
  final uploadedExerciseScoreIds = <String, List<String>>{};
  final uploadedExerciseMetadata = <String, ExerciseMetadataModel>{};
  final uploadedExerciseCategoryIds = <String, String?>{};
  final uploadedRoutineEntries = <String, List<PracticeRoutineEntryModel>>{};
  final uploadedSessionEntries = <String, List<PracticeSessionEntryModel>>{};

  final deletedOnServer = <String>[];

  @override
  Future<ServerInfoModel> getServerInfo(Uri baseUri) async => ServerInfoModel(
    server: "sheetopia-sync",
    serverVersion: "0.0.0",
    apiVersion: apiVersion,
    time: syncTime,
  );

  @override
  Future<SyncConnection> login(
    Uri baseUri, {
    required String user,
    required String password,
  }) async => SyncConnection(baseUri: baseUri, authKey: "key");

  @override
  Future<String> getUser(SyncConnection con) async => "alice";

  @override
  Future<List<ScoreModel>> getScores(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => [];

  @override
  Future<List<TagModel>> getTags(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => [];

  @override
  Future<List<SetlistModel>> getSetlists(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => [];

  @override
  Future<List<RemotelyDeleted>> getDeletedScores(
    SyncConnection con, {
    DateTime? since,
  }) async => [];

  @override
  Future<List<RemotelyDeleted>> getDeletedTags(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedTags;

  @override
  Future<List<RemotelyDeleted>> getDeletedSetlists(
    SyncConnection con, {
    DateTime? since,
  }) async => [];

  @override
  Future<List<ExerciseCategoryModel>> getExerciseCategories(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => categories;

  @override
  Future<List<ExerciseModel>> getExercises(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => exercises;

  @override
  Future<List<PracticeRoutineModel>> getPracticeRoutines(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => routines;

  @override
  Future<List<PracticeSessionModel>> getPracticeSessions(
    SyncConnection con, {
    DateTime? changedAfter,
  }) async => sessions;

  @override
  Future<List<RemotelyDeleted>> getDeletedExerciseCategories(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedCategories;

  @override
  Future<List<RemotelyDeleted>> getDeletedExercises(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedExercises;

  @override
  Future<List<RemotelyDeleted>> getDeletedPracticeRoutines(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedRoutines;

  @override
  Future<List<RemotelyDeleted>> getDeletedPracticeSessions(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedSessions;

  @override
  Future<void> updateExerciseCategory(
    SyncConnection con,
    String categoryId, {
    required String name,
    required int position,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async => uploadedCategories.add((id: categoryId, writtenAt: writtenAt));

  @override
  Future<void> updateExercise(
    SyncConnection con,
    String exerciseId, {
    required String name,
    required String? categoryId,
    required List<String> tagIds,
    required List<String> scoreIds,
    required ExerciseMetadataModel metadata,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async {
    uploadedExercises.add((id: exerciseId, writtenAt: writtenAt));
    uploadedExerciseTagIds[exerciseId] = tagIds;
    uploadedExerciseScoreIds[exerciseId] = scoreIds;
    uploadedExerciseMetadata[exerciseId] = metadata;
    uploadedExerciseCategoryIds[exerciseId] = categoryId;
  }

  @override
  Future<void> updatePracticeRoutine(
    SyncConnection con,
    String routineId, {
    required String name,
    required PracticeRoutineMetadataModel metadata,
    required List<PracticeRoutineEntryModel> entries,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async {
    uploadedRoutines.add((id: routineId, writtenAt: writtenAt));
    uploadedRoutineEntries[routineId] = entries;
  }

  @override
  Future<void> updatePracticeSession(
    SyncConnection con,
    String sessionId, {
    required DateTime startedAt,
    required DateTime? endedAt,
    required String? routineId,
    required PracticeSessionMetadataModel metadata,
    required List<PracticeSessionEntryModel> entries,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async {
    uploadedSessions.add((id: sessionId, writtenAt: writtenAt));
    uploadedSessionEntries[sessionId] = entries;
  }

  @override
  Future<void> deleteExerciseCategory(
    SyncConnection con,
    String categoryId,
  ) async => deletedOnServer.add(categoryId);

  @override
  Future<void> deleteExercise(SyncConnection con, String exerciseId) async =>
      deletedOnServer.add(exerciseId);

  @override
  Future<void> deletePracticeRoutine(
    SyncConnection con,
    String routineId,
  ) async => deletedOnServer.add(routineId);

  @override
  Future<void> deletePracticeSession(
    SyncConnection con,
    String sessionId,
  ) async => deletedOnServer.add(sessionId);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();
  // the repository logs on every kept and every dropped row
  Log.init(LogRepository());
  Log.level = Level.error;

  late Directory tempDir;
  late Database db;
  late ScoresRepository scoresRepo;
  late SetlistsRepository setlistsRepo;
  late PracticeRepository practiceRepo;
  late _FakeSyncService service;
  late SyncRepository repo;

  const categoryId = "category-1";
  const exerciseId = "exercise-1";
  const routineId = "routine-1";
  const entryId = "routine-entry-1";
  const sessionId = "session-1";
  const tagId = "tag-1";

  final deletedAt = DateTime.utc(2026, 9, 2, 15);
  final importedAt = deletedAt.add(const Duration(minutes: 5));
  final contentTime = DateTime.utc(2026, 1, 1);
  final remoteTime = DateTime.utc(2026, 2, 1);

  ExerciseMetadataModel metadata({
    String? description = "",
    String? instrument = "",
    int? targetBpm = 0,
  }) => ExerciseMetadataModel(
    description: description,
    source: "",
    sourceLink: "",
    instrument: instrument,
    targetBpm: targetBpm,
  );

  Future<void> createCategory({DateTime? writtenAt, bool uploaded = true}) =>
      db.managers.exerciseCategoriesTable.create(
        (o) => o(
          id: categoryId,
          name: "Scales",
          position: 0,
          updatedAt: Value(contentTime),
          writtenAt: Value(writtenAt),
          uploaded: Value(uploaded),
        ),
      );

  Future<void> createExercise({
    DateTime? writtenAt,
    bool uploaded = true,
    String? category,
  }) => db.managers.exercisesTable.create(
    (o) => o(
      id: exerciseId,
      name: "C major",
      category: Value(category),
      description: const Value("Two octaves"),
      updatedAt: Value(contentTime),
      writtenAt: Value(writtenAt),
      uploaded: Value(uploaded),
    ),
  );

  Future<void> createRoutine({
    DateTime? writtenAt,
    bool uploaded = true,
    bool withEntry = false,
  }) async {
    await db.managers.practiceRoutinesTable.create(
      (o) => o(
        id: routineId,
        name: "Morning",
        updatedAt: Value(contentTime),
        writtenAt: Value(writtenAt),
        uploaded: Value(uploaded),
      ),
    );
    if (withEntry) {
      await db.managers.practiceRoutineEntriesTable.create(
        (o) => o(
          id: entryId,
          routine: routineId,
          exercise: exerciseId,
          position: 0,
          targetDuration: const Value(Duration(minutes: 5)),
        ),
      );
    }
  }

  Future<void> createSession({
    DateTime? writtenAt,
    bool uploaded = true,
    DateTime? runningSince,
  }) async {
    await db.managers.practiceSessionsTable.create(
      (o) => o(
        id: sessionId,
        startedAt: contentTime,
        endedAt: Value(contentTime.add(const Duration(minutes: 30))),
        routine: const Value(routineId),
        updatedAt: Value(contentTime),
        writtenAt: Value(writtenAt),
        uploaded: Value(uploaded),
      ),
    );
    await db.managers.practiceSessionEntriesTable.create(
      (o) => o(
        id: "session-entry-1",
        session: sessionId,
        exercise: exerciseId,
        routineEntry: const Value(entryId),
        duration: const Value(Duration(minutes: 3)),
        runningSince: Value(runningSince),
      ),
    );
  }

  // login kicks off a sync without awaiting it
  Future<void> syncAndWait() async {
    await repo.login(
      baseUri: Uri.parse("https://example.invalid"),
      user: "alice",
      password: "secret",
    );
    while (repo.state.value == SyncState.syncing ||
        repo.state.value == SyncState.none) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(repo.state.value, SyncState.success);
  }

  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 2000 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(done(), isTrue, reason: "timed out waiting for the sync");
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("sheetopia-practice-sync");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    setlistsRepo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
    practiceRepo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    service = _FakeSyncService();
    repo = SyncRepository(
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
      practiceRepo: practiceRepo,
      keyValue: KeyValueRepository(database: db),
      db: db,
      syncService: service,
      thumbnailService: ThumbnailService(),
      encryptedStorage: _InMemoryEncryptedStorage(),
    );
  });

  tearDown(() async {
    await repo.logout();
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test("local practice changes are uploaded", () async {
    await createCategory(uploaded: false);
    await createExercise(uploaded: false, category: categoryId);
    await createRoutine(uploaded: false, withEntry: true);
    await createSession(uploaded: false);

    await syncAndWait();

    expect(service.uploadedCategories, [(id: categoryId, writtenAt: null)]);
    expect(service.uploadedExercises, [(id: exerciseId, writtenAt: null)]);
    expect(service.uploadedRoutines, [(id: routineId, writtenAt: null)]);
    expect(service.uploadedSessions, [(id: sessionId, writtenAt: null)]);
    expect(service.uploadedExerciseCategoryIds[exerciseId], categoryId);
    expect(
      service.uploadedExerciseMetadata[exerciseId]?.description,
      "Two octaves",
    );
    expect(service.uploadedRoutineEntries[routineId]?.single.id, entryId);
    expect(
      service.uploadedRoutineEntries[routineId]?.single.metadata.targetDuration,
      const Duration(minutes: 5).inMilliseconds,
    );
    expect(
      service.uploadedSessionEntries[sessionId]?.single.metadata.duration,
      const Duration(minutes: 3).inMilliseconds,
    );

    expect(
      await db.managers.exercisesTable
          .filter((f) => f.id(exerciseId) & f.uploaded.isTrue())
          .count(),
      1,
      reason: "an accepted upload settles the local write",
    );
  });

  test("a server before 0.4 receives no practice data", () async {
    service.apiVersion = "0.3.0";
    await createCategory(uploaded: false);
    await createExercise(uploaded: false);

    await syncAndWait();

    expect(service.uploadedCategories, isEmpty);
    expect(service.uploadedExercises, isEmpty);
  });

  test("remote practice data is stored", () async {
    await db.managers.tagsTable.create(
      (o) => o(
        id: tagId,
        name: "Warm up",
        color: 1,
        type: const Value(TagType.exercise),
        updatedAt: Value(contentTime),
        uploaded: const Value(true),
      ),
    );
    service.categories = [
      ExerciseCategoryModel(
        id: categoryId,
        name: "Scales",
        position: 3,
        updatedAt: remoteTime,
      ),
    ];
    service.exercises = [
      ExerciseModel(
        id: exerciseId,
        name: "C major",
        categoryId: categoryId,
        tagIds: [tagId, "unknown-tag"],
        scoreIds: const ["score-2", "score-1"],
        metadata: metadata(description: "Two octaves", targetBpm: 90),
        updatedAt: remoteTime,
      ),
    ];
    service.routines = [
      PracticeRoutineModel(
        id: routineId,
        name: "Morning",
        metadata: PracticeRoutineMetadataModel(description: "Before breakfast"),
        entries: [
          PracticeRoutineEntryModel(
            id: entryId,
            exerciseId: exerciseId,
            metadata: PracticeRoutineEntryMetadataModel(
              extraNotes: "",
              defaultScoreId: "score-1",
              targetDuration: const Duration(minutes: 5).inMilliseconds,
            ),
          ),
          PracticeRoutineEntryModel(
            id: "entry-of-unknown-exercise",
            exerciseId: "unknown-exercise",
            metadata: PracticeRoutineEntryMetadataModel(
              extraNotes: "",
              defaultScoreId: "",
              targetDuration: 0,
            ),
          ),
        ],
        updatedAt: remoteTime,
      ),
    ];
    service.sessions = [
      PracticeSessionModel(
        id: sessionId,
        startedAt: contentTime,
        endedAt: null,
        routineId: routineId,
        metadata: PracticeSessionMetadataModel(description: ""),
        entries: [
          PracticeSessionEntryModel(
            id: "session-entry-1",
            exerciseId: exerciseId,
            routineEntryId: entryId,
            metadata: PracticeSessionEntryMetadataModel(
              duration: const Duration(minutes: 3).inMilliseconds,
            ),
          ),
        ],
        updatedAt: remoteTime,
      ),
    ];

    await syncAndWait();

    final category = await db.managers.exerciseCategoriesTable
        .filter((f) => f.id(categoryId))
        .getSingle();
    expect(category.position, 3);
    expect(category.uploaded, isTrue);

    final exercise = await db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .getSingle();
    expect(exercise.category, categoryId);
    expect(exercise.description, "Two octaves");
    expect(exercise.targetBpm, 90);
    expect(exercise.instrument, isNull, reason: "an empty field means unset");

    expect(
      await db.managers.exerciseTagsTable
          .filter((f) => f.exercise.id(exerciseId))
          .map((t) => t.tag)
          .get(),
      [tagId],
      reason: "a tag this device does not know is dropped",
    );
    final scores = await db.managers.exerciseScoresTable
        .filter((f) => f.exercise.id(exerciseId))
        .orderBy((o) => o.position.asc())
        .get();
    expect(scores.map((s) => s.score), ["score-2", "score-1"]);

    final entries = await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(routineId))
        .get();
    expect(entries.map((e) => e.id), [
      entryId,
    ], reason: "an entry of an unknown exercise is dropped");
    expect(entries.single.targetDuration, const Duration(minutes: 5));
    expect(entries.single.defaultScore, "score-1");

    final session = await db.managers.practiceSessionsTable
        .filter((f) => f.id(sessionId))
        .getSingle();
    expect(session.endedAt, isNull);
    expect(session.routine, routineId);
    expect(
      await db.managers.practiceSessionEntriesTable
          .filter((f) => f.session.id(sessionId))
          .getSingle(),
      isNotNull,
    );
  });

  test("an older remote exercise does not overwrite the local one", () async {
    await createExercise();
    service.exercises = [
      ExerciseModel(
        id: exerciseId,
        name: "Renamed",
        categoryId: null,
        tagIds: const [],
        scoreIds: const [],
        metadata: metadata(),
        updatedAt: contentTime.subtract(const Duration(days: 1)),
      ),
    ];

    await syncAndWait();

    final exercise = await db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .getSingle();
    expect(exercise.name, "C major");
  });

  test("an exercise of an unknown category loses its category", () async {
    service.exercises = [
      ExerciseModel(
        id: exerciseId,
        name: "C major",
        categoryId: "unknown-category",
        tagIds: const [],
        scoreIds: const [],
        metadata: metadata(),
        updatedAt: remoteTime,
      ),
    ];

    await syncAndWait();

    final exercise = await db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .getSingle();
    expect(exercise.category, isNull);
  });

  test("a deleted category unlinks its exercises", () async {
    await createCategory();
    await createExercise(category: categoryId);
    service.deletedCategories = [(id: categoryId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.exerciseCategoriesTable
          .filter((f) => f.id(categoryId))
          .count(),
      0,
    );
    final exercise = await db.managers.exercisesTable
        .filter((f) => f.id(exerciseId))
        .getSingle();
    expect(exercise.category, isNull);
  });

  test("a deleted exercise loses its routine entries", () async {
    await createExercise();
    await createRoutine(withEntry: true);
    service.deletedExercises = [(id: exerciseId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.exercisesTable.filter((f) => f.id(exerciseId)).count(),
      0,
    );
    expect(
      await db.managers.practiceRoutineEntriesTable
          .filter((f) => f.id(entryId))
          .count(),
      0,
    );
    expect(
      await db.managers.practiceRoutinesTable
          .filter((f) => f.id(routineId))
          .count(),
      1,
      reason: "only the entry goes, the routine stays",
    );
  });

  test("a session with a running stopwatch is not uploaded", () async {
    await createExercise();
    await createRoutine(withEntry: true);
    await createSession(uploaded: false, runningSince: contentTime);

    await syncAndWait();

    expect(service.uploadedSessions, isEmpty);
    expect(
      await db.managers.practiceSessionsTable
          .filter((f) => f.id(sessionId) & f.uploaded.isFalse())
          .count(),
      1,
      reason: "the session stays pending until the stopwatch is paused",
    );

    await db.managers.practiceSessionEntriesTable
        .filter((f) => f.session.id(sessionId))
        .update((o) => o(runningSince: const Value(null)));
    await repo.syncNow();
    await waitFor(() => service.uploadedSessions.isNotEmpty);

    expect(service.uploadedSessions, [(id: sessionId, writtenAt: null)]);
    expect(
      service.uploadedSessionEntries[sessionId]?.single.metadata.duration,
      const Duration(minutes: 3).inMilliseconds,
    );
  });

  test("a deleted tag drops it from its exercises too", () async {
    await createExercise();
    await db.managers.tagsTable.create(
      (o) => o(
        id: tagId,
        name: "Warm up",
        color: 0,
        updatedAt: Value(contentTime),
        uploaded: const Value(true),
      ),
    );
    await db.managers.exerciseTagsTable.create(
      (o) => o(exercise: exerciseId, tag: tagId),
    );
    service.deletedTags = [(id: tagId, deletedAt: deletedAt)];

    final announced = <String>{};
    practiceRepo.updatedExerciseIds.listen(announced.addAll);

    await syncAndWait();

    expect(
      await db.managers.exerciseTagsTable
          .filter((f) => f.exercise.id(exerciseId))
          .count(),
      0,
    );
    await waitFor(() => announced.contains(exerciseId));
  });

  test("a deleted exercise renumbers the remaining routine entries", () async {
    await createExercise();
    await createRoutine(withEntry: true);
    await db.managers.exercisesTable.create(
      (o) => o(id: "exercise-2", name: "G major", updatedAt: Value(contentTime)),
    );
    await db.managers.practiceRoutineEntriesTable.create(
      (o) => o(
        id: "routine-entry-2",
        routine: routineId,
        exercise: "exercise-2",
        position: 1,
      ),
    );
    service.deletedExercises = [(id: exerciseId, deletedAt: deletedAt)];

    await syncAndWait();

    final entries = await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(routineId))
        .get();
    expect(entries.single.id, "routine-entry-2");
    expect(entries.single.position, 0);
  });

  test("a deleted routine and session are removed locally", () async {
    await createRoutine();
    await createExercise();
    await createSession();
    service.deletedRoutines = [(id: routineId, deletedAt: deletedAt)];
    service.deletedSessions = [(id: sessionId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.practiceRoutinesTable
          .filter((f) => f.id(routineId))
          .count(),
      0,
    );
    expect(
      await db.managers.practiceSessionsTable
          .filter((f) => f.id(sessionId))
          .count(),
      0,
    );
  });

  test("imported practice rows survive their tombstones", () async {
    await createCategory(writtenAt: importedAt);
    await createExercise(writtenAt: importedAt, category: categoryId);
    await createRoutine(writtenAt: importedAt, withEntry: true);
    await createSession(writtenAt: importedAt);
    service.deletedCategories = [(id: categoryId, deletedAt: deletedAt)];
    service.deletedExercises = [(id: exerciseId, deletedAt: deletedAt)];
    service.deletedRoutines = [(id: routineId, deletedAt: deletedAt)];
    service.deletedSessions = [(id: sessionId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.exercisesTable.filter((f) => f.id(exerciseId)).count(),
      1,
    );
    expect(service.uploadedCategories, [
      (id: categoryId, writtenAt: importedAt),
    ]);
    expect(service.uploadedExercises, [
      (id: exerciseId, writtenAt: importedAt),
    ]);
    expect(service.uploadedRoutines, [(id: routineId, writtenAt: importedAt)]);
    expect(service.uploadedSessions, [(id: sessionId, writtenAt: importedAt)]);
  });

  test("local deletions are pushed to the server", () async {
    await createCategory();
    await createExercise(category: categoryId);
    await createRoutine(withEntry: true);
    await syncAndWait();

    await practiceRepo.deleteRoutine(routineId);
    await practiceRepo.deleteExercise(exerciseId);
    await practiceRepo.deleteCategory(categoryId);

    // the delete streams reach the sync repository first and would reschedule the sync
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await repo.syncNow();
    await waitFor(() => service.deletedOnServer.length == 3);

    expect(service.deletedOnServer, [routineId, exerciseId, categoryId]);
    expect(await db.managers.deletedExercisesTable.count(), 0);
    expect(await db.managers.deletedPracticeRoutinesTable.count(), 0);
    expect(await db.managers.deletedExerciseCategoriesTable.count(), 0);
  });
}
