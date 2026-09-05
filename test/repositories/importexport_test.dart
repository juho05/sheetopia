/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/database/tags_table.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
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

class _FakeFileSelector extends FileSelectorPlatform
    with MockPlatformInterfaceMixin {
  String? saveLocation;
  String? fileToOpen;

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    return saveLocation == null ? null : FileSaveLocation(saveLocation!);
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    return fileToOpen == null ? null : XFile(fileToOpen!);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory exportDir;
  late Database db;
  late ScoresRepository scoresRepo;
  late SetlistsRepository setlistsRepo;
  late PracticeRepository practiceRepo;
  late SyncRepository syncRepo;
  late ImportExportRepository repo;
  late _FakeFileSelector fileSelector;

  const scoreId = "score-1";
  const tagId = "tag-1";
  const setlistId = "setlist-1";
  const exerciseTagId = "tag-2";
  const categoryId = "category-1";
  const exerciseId = "exercise-1";
  const routineId = "routine-1";
  const routineEntryId = "routine-entry-1";
  const sessionId = "session-1";
  const sessionEntryId = "session-entry-1";

  final contentTime = DateTime.utc(2026, 1, 1);

  Future<void> createScore() async {
    await db.managers.tagsTable.create(
      (o) => o(
        id: tagId,
        name: "Baroque",
        color: 0xff00ff00,
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.scoresTable.create(
      (o) => o(
        id: scoreId,
        title: "Prelude",
        composer: const Value("Bach"),
        source: const Value("IMSLP"),
        sourceLink: const Value("https://imslp.org"),
        searchText: " prelude bach ",
        fileDownloaded: true,
        fileType: FileType.pdf,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );
    await db.managers.scoreTagsTable.create(
      (o) => o(score: scoreId, tag: tagId),
    );

    await scoresRepo.createScoreDir(scoreId);
    final file = await scoresRepo.scoreFile(scoreId, FileType.pdf);
    await file.writeAsString("%PDF-1.4 fake");

    await db.managers.setlistsTable.create(
      (o) => o(id: setlistId, name: "Recital", updatedAt: Value(contentTime)),
    );
    await db.managers.setlistEntriesTable.create(
      (o) => o(setlist: setlistId, score: scoreId, position: 0),
    );
  }

  Future<void> createPracticeData() async {
    await db.managers.tagsTable.create(
      (o) => o(
        id: exerciseTagId,
        name: "Warmup",
        color: 0xff0000ff,
        type: const Value(TagType.exercise),
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.exerciseCategoriesTable.create(
      (o) => o(
        id: categoryId,
        name: "Technique",
        position: 0,
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.exercisesTable.create(
      (o) => o(
        id: exerciseId,
        name: "Scales",
        category: const Value(categoryId),
        description: const Value("All major scales"),
        source: const Value("Hanon"),
        sourceLink: const Value("https://example.org"),
        instrument: const Value("Piano"),
        targetBpm: const Value(120),
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.exerciseTagsTable.create(
      (o) => o(exercise: exerciseId, tag: exerciseTagId),
    );
    await db.managers.exerciseScoresTable.create(
      (o) => o(exercise: exerciseId, score: scoreId, position: 0),
    );

    await db.managers.practiceRoutinesTable.create(
      (o) => o(
        id: routineId,
        name: "Morning",
        description: const Value("Before breakfast"),
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.practiceRoutineEntriesTable.create(
      (o) => o(
        id: routineEntryId,
        routine: routineId,
        exercise: exerciseId,
        position: 0,
        extraNotes: const Value("Hands separately"),
        targetDuration: const Value(Duration(minutes: 5)),
        defaultScore: const Value(scoreId),
      ),
    );

    await db.managers.practiceSessionsTable.create(
      (o) => o(
        id: sessionId,
        startedAt: contentTime,
        endedAt: Value(contentTime.add(const Duration(minutes: 30))),
        routine: const Value(routineId),
        description: const Value("Went well"),
        updatedAt: Value(contentTime),
      ),
    );
    await db.managers.practiceSessionEntriesTable.create(
      (o) => o(
        id: sessionEntryId,
        session: sessionId,
        exercise: exerciseId,
        routineEntry: const Value(routineEntryId),
        duration: const Value(Duration(minutes: 7)),
      ),
    );
  }

  Future<String> exportAll() async {
    final target = path.join(exportDir.path, "export.zip");
    fileSelector.saveLocation = target;
    expect(await repo.export(), isTrue);
    expect(await File(target).exists(), isTrue);
    return target;
  }

  Future<void> importFrom(String zipPath) async {
    fileSelector.fileToOpen = zipPath;
    expect(await repo.import(), isTrue);
  }

  Future<String> stripPracticeFiles(String zipPath) async {
    final dir = await Directory(
      path.join(tempDir.path, "stripped"),
    ).create(recursive: true);
    await extractFileToDisk(zipPath, dir.path);
    for (final name in [
      "exercise_categories.json",
      "exercises.json",
      "practice_routines.json",
      "practice_sessions.json",
    ]) {
      await File(path.join(dir.path, name)).delete();
    }

    final target = path.join(exportDir.path, "stripped.zip");
    final outStream = OutputFileStream(target);
    ZipEncoder().encodeStream(
      createArchiveFromDirectory(dir, includeDirName: false),
      outStream,
      autoClose: true,
    );
    return target;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("importexport_test");
    exportDir = await Directory(
      path.join(tempDir.path, "export-target"),
    ).create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    fileSelector = _FakeFileSelector();
    FileSelectorPlatform.instance = fileSelector;

    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    setlistsRepo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
    practiceRepo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    syncRepo = SyncRepository(
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
      practiceRepo: practiceRepo,
      keyValue: KeyValueRepository(database: db),
      db: db,
      syncService: SyncService(),
      thumbnailService: ThumbnailService(),
      encryptedStorage: _InMemoryEncryptedStorage(),
    );
    repo = ImportExportRepository(
      thumbnailService: ThumbnailService(),
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
      practiceRepo: practiceRepo,
      syncRepo: syncRepo,
      db: db,
    );

    await createScore();
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test("re-importing a deleted score restores it under the same id", () async {
    final zip = await exportAll();

    await scoresRepo.deleteScore(scoreId);
    expect(await db.managers.scoresTable.count(), 0);

    await importFrom(zip);

    final score = await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingle();
    expect(score.title, "Prelude");
    expect(score.composer, "Bach");
    expect(score.source, "IMSLP");
    expect(score.sourceLink, "https://imslp.org");
    expect(score.metadataUpdatedAt, contentTime);
    expect(score.writtenAt, isNotNull);
    expect(score.writtenAt!.isAfter(contentTime), isTrue);
    expect(score.metadataUploaded, isFalse);
    expect(score.fileDownloaded, isTrue);

    final tags = await db.managers.scoreTagsTable
        .filter((f) => f.score.id(scoreId))
        .get();
    expect(tags.map((t) => t.tag), [tagId]);

    expect(await db.managers.deletedScoresTable.count(), 0);
  });

  test("re-importing a deleted tag restores it under the same id", () async {
    final zip = await exportAll();

    await scoresRepo.deleteTag(tagId);
    expect(await db.managers.tagsTable.count(), 0);
    expect(await db.managers.deletedTagsTable.count(), 1);

    await importFrom(zip);

    final tag = await db.managers.tagsTable
        .filter((f) => f.id(tagId))
        .getSingle();
    expect(tag.name, "Baroque");
    expect(tag.updatedAt, contentTime);
    expect(tag.writtenAt, isNotNull);
    expect(tag.writtenAt!.isAfter(contentTime), isTrue);
    expect(tag.uploaded, isFalse);

    expect(await db.managers.deletedTagsTable.count(), 0);
  });

  test("an exercise tag keeps its type through an export", () async {
    final exerciseTagId = db.newId();
    await db.managers.tagsTable.create(
      (o) => o(
        id: exerciseTagId,
        name: "Warmup",
        color: 0xff0000ff,
        type: const Value(TagType.exercise),
        updatedAt: Value(contentTime),
      ),
    );
    final zip = await exportAll();

    await scoresRepo.deleteTag(exerciseTagId);
    await scoresRepo.deleteTag(tagId);
    expect(await db.managers.tagsTable.count(), 0);

    await importFrom(zip);

    final tags = await db.managers.tagsTable.get();
    expect(
      {for (final t in tags) t.name: t.type},
      {"Baroque": TagType.score, "Warmup": TagType.exercise},
    );
  });

  test("a tag exported before types existed has no type", () {
    final tag = TagModel.fromJson({
      "id": "a",
      "name": "Baroque",
      "color": 0xff00ff00,
      "updatedAt": "2026-01-01T00:00:00.000Z",
    });

    expect(tag.type, isNull);
    expect(tag.toJson().containsKey("type"), isFalse);
  });

  test("an exercise score keeps its type through an export", () async {
    const exerciseScoreId = "score-2";
    await db.managers.scoresTable.create(
      (o) => o(
        id: exerciseScoreId,
        title: "Scales",
        searchText: " scales ",
        fileDownloaded: true,
        fileType: FileType.pdf,
        type: const Value(ScoreType.exercise),
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );
    await scoresRepo.createScoreDir(exerciseScoreId);
    final file = await scoresRepo.scoreFile(exerciseScoreId, FileType.pdf);
    await file.writeAsString("%PDF-1.4 fake");

    final zip = await exportAll();

    await scoresRepo.deleteScore(exerciseScoreId);
    await scoresRepo.deleteScore(scoreId);
    expect(await db.managers.scoresTable.count(), 0);

    await importFrom(zip);

    final scores = await db.managers.scoresTable.get();
    expect(
      {for (final s in scores) s.title: s.type},
      {"Prelude": ScoreType.score, "Scales": ScoreType.exercise},
    );
  });

  test("a score exported before types existed has no type", () {
    final score = ScoreModel.fromJson({
      "id": "a",
      "title": "Prelude",
      "metadataUpdatedAt": "2026-01-01T00:00:00.000Z",
      "fileUpdatedAt": "2026-01-01T00:00:00.000Z",
      "fileType": "pdf",
      "tagIds": <String>[],
      "metadata": <String, dynamic>{},
    });

    expect(score.type, isNull);
    expect(score.toJson().containsKey("type"), isFalse);
  });

  test("re-importing a deleted setlist restores it with its entries", () async {
    final zip = await exportAll();

    await setlistsRepo.deleteSetlist(setlistId);
    expect(await db.managers.setlistsTable.count(), 0);
    expect(await db.managers.deletedSetlistsTable.count(), 1);

    await importFrom(zip);

    final setlist = await db.managers.setlistsTable
        .filter((f) => f.id(setlistId))
        .getSingle();
    expect(setlist.name, "Recital");
    expect(setlist.updatedAt, contentTime);
    expect(setlist.writtenAt, isNotNull);
    expect(setlist.writtenAt!.isAfter(contentTime), isTrue);
    expect(setlist.uploaded, isFalse);

    final entries = await db.managers.setlistEntriesTable
        .filter((f) => f.setlist.id(setlistId))
        .get();
    expect(entries.map((e) => e.score), [scoreId]);

    expect(await db.managers.deletedSetlistsTable.count(), 0);
  });

  test("importing data the local database already has is a no-op", () async {
    final zip = await exportAll();

    await scoresRepo.updateScore(
      scoreId,
      title: "Prelude in C",
      composer: "Bach",
      notes: "",
    );
    await scoresRepo.updateScoreSource(
      scoreId,
      source: "Henle",
      sourceLink: "",
    );
    await scoresRepo.updateTag(tagId, name: "Barock", color: Colors.red);
    await setlistsRepo.renameSetlist(setlistId, "Rezital");

    await importFrom(zip);

    final score = await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingle();
    expect(score.title, "Prelude in C");
    expect(score.source, "Henle");
    expect(score.sourceLink, isNull);
    expect(score.writtenAt, isNull);

    final tag = await db.managers.tagsTable
        .filter((f) => f.id(tagId))
        .getSingle();
    expect(tag.name, "Barock");
    expect(tag.writtenAt, isNull);

    final setlist = await db.managers.setlistsTable
        .filter((f) => f.id(setlistId))
        .getSingle();
    expect(setlist.name, "Rezital");
    expect(setlist.writtenAt, isNull);
  });

  test(
    "re-importing a deleted exercise restores it under the same id",
    () async {
      await createPracticeData();
      final zip = await exportAll();

      await practiceRepo.deleteExercise(exerciseId);
      expect(await db.managers.exercisesTable.count(), 0);
      expect(await db.managers.deletedExercisesTable.count(), 1);

      await importFrom(zip);

      final exercise = await db.managers.exercisesTable
          .filter((f) => f.id(exerciseId))
          .getSingle();
      expect(exercise.name, "Scales");
      expect(exercise.category, categoryId);
      expect(exercise.description, "All major scales");
      expect(exercise.source, "Hanon");
      expect(exercise.sourceLink, "https://example.org");
      expect(exercise.instrument, "Piano");
      expect(exercise.targetBpm, 120);
      expect(exercise.updatedAt, contentTime);
      expect(exercise.writtenAt, isNotNull);
      expect(exercise.writtenAt!.isAfter(contentTime), isTrue);
      expect(exercise.uploaded, isFalse);

      final tags = await db.managers.exerciseTagsTable
          .filter((f) => f.exercise.id(exerciseId))
          .get();
      expect(tags.map((t) => t.tag), [exerciseTagId]);

      final scores = await db.managers.exerciseScoresTable
          .filter((f) => f.exercise.id(exerciseId))
          .get();
      expect(scores.map((s) => s.score), [scoreId]);

      expect(await db.managers.deletedExercisesTable.count(), 0);
    },
  );

  test(
    "re-importing a deleted category restores it under the same id",
    () async {
      await createPracticeData();
      final zip = await exportAll();

      await practiceRepo.deleteCategory(categoryId);
      expect(await db.managers.exerciseCategoriesTable.count(), 0);
      expect(await db.managers.deletedExerciseCategoriesTable.count(), 1);

      await importFrom(zip);

      final category = await db.managers.exerciseCategoriesTable
          .filter((f) => f.id(categoryId))
          .getSingle();
      expect(category.name, "Technique");
      expect(category.position, 0);
      expect(category.updatedAt, contentTime);
      expect(category.writtenAt, isNotNull);
      expect(category.writtenAt!.isAfter(contentTime), isTrue);
      expect(category.uploaded, isFalse);

      expect(await db.managers.deletedExerciseCategoriesTable.count(), 0);
    },
  );

  test("re-importing a deleted routine restores it with its entries", () async {
    await createPracticeData();
    final zip = await exportAll();

    await practiceRepo.deleteRoutine(routineId);
    expect(await db.managers.practiceRoutinesTable.count(), 0);
    expect(await db.managers.deletedPracticeRoutinesTable.count(), 1);

    await importFrom(zip);

    final routine = await db.managers.practiceRoutinesTable
        .filter((f) => f.id(routineId))
        .getSingle();
    expect(routine.name, "Morning");
    expect(routine.description, "Before breakfast");
    expect(routine.updatedAt, contentTime);
    expect(routine.writtenAt, isNotNull);
    expect(routine.writtenAt!.isAfter(contentTime), isTrue);
    expect(routine.uploaded, isFalse);

    final entry = await db.managers.practiceRoutineEntriesTable
        .filter((f) => f.routine.id(routineId))
        .getSingle();
    expect(entry.id, routineEntryId);
    expect(entry.exercise, exerciseId);
    expect(entry.position, 0);
    expect(entry.extraNotes, "Hands separately");
    expect(entry.targetDuration, const Duration(minutes: 5));
    expect(entry.defaultScore, scoreId);

    expect(await db.managers.deletedPracticeRoutinesTable.count(), 0);
  });

  test("re-importing a deleted session restores it with its entries", () async {
    await createPracticeData();
    final zip = await exportAll();

    await db.managers.practiceSessionsTable
        .filter((f) => f.id(sessionId))
        .delete();
    await db.managers.deletedPracticeSessionsTable.create(
      (o) => o(sessionId: sessionId),
    );
    expect(await db.managers.practiceSessionEntriesTable.count(), 0);

    await importFrom(zip);

    final session = await db.managers.practiceSessionsTable
        .filter((f) => f.id(sessionId))
        .getSingle();
    expect(session.startedAt, contentTime);
    expect(session.endedAt, contentTime.add(const Duration(minutes: 30)));
    expect(session.routine, routineId);
    expect(session.description, "Went well");
    expect(session.updatedAt, contentTime);
    expect(session.writtenAt, isNotNull);
    expect(session.writtenAt!.isAfter(contentTime), isTrue);
    expect(session.uploaded, isFalse);

    final entry = await db.managers.practiceSessionEntriesTable
        .filter((f) => f.session.id(sessionId))
        .getSingle();
    expect(entry.id, sessionEntryId);
    expect(entry.exercise, exerciseId);
    expect(entry.routineEntry, routineEntryId);
    expect(entry.duration, const Duration(minutes: 7));

    expect(await db.managers.deletedPracticeSessionsTable.count(), 0);
  });

  test(
    "importing practice data the local database already has is a no-op",
    () async {
      await createPracticeData();
      final zip = await exportAll();

      await practiceRepo.updateExercise(
        exerciseId,
        name: "Arpeggios",
        description: "",
        instrument: "Piano",
      );
      await practiceRepo.renameCategory(categoryId, "Technik");
      await practiceRepo.updateRoutine(
        routineId,
        name: "Abend",
        description: "Before breakfast",
      );

      await importFrom(zip);

      final exercise = await db.managers.exercisesTable
          .filter((f) => f.id(exerciseId))
          .getSingle();
      expect(exercise.name, "Arpeggios");
      expect(exercise.description, isNull);
      expect(exercise.writtenAt, isNull);

      final category = await db.managers.exerciseCategoriesTable
          .filter((f) => f.id(categoryId))
          .getSingle();
      expect(category.name, "Technik");
      expect(category.writtenAt, isNull);

      final routine = await db.managers.practiceRoutinesTable
          .filter((f) => f.id(routineId))
          .getSingle();
      expect(routine.name, "Abend");
      expect(routine.writtenAt, isNull);
    },
  );

  test("an export without practice data imports cleanly", () async {
    await createPracticeData();
    final zip = await exportAll();
    final stripped = await stripPracticeFiles(zip);

    await practiceRepo.deleteExercise(exerciseId);
    expect(await db.managers.exercisesTable.count(), 0);

    await importFrom(stripped);

    expect(await db.managers.exercisesTable.count(), 0);
    expect(await db.managers.scoresTable.count(), 1);
  });
}
