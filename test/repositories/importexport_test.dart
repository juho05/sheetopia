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
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:sheetopia/data/repositories/importexport/archive_reader.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
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
import 'package:sheetopia/data/services/pdf_validation_service.dart';
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
  Log.init(LogRepository());
  Log.level = Level.off;

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
  const recordId = "record-1";

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
        arranger: const Value("Busoni"),
        difficulty: const Value(4),
        cropExcluded: const Value(true),
        source: const Value("IMSLP"),
        sourceLink: const Value("https://imslp.org"),
        searchText: " prelude bach busoni ",
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
        progressResetAt: Value(contentTime),
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

    await db.managers.practiceRecordsTable.create(
      (o) => o(
        id: recordId,
        exercise: exerciseId,
        routine: const Value(routineId),
        routineEntry: const Value(routineEntryId),
        startedAt: contentTime,
        duration: const Value(Duration(minutes: 7)),
        updatedAt: Value(contentTime),
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
      "practice_records.json",
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
    scoresRepo = ScoresRepository(
      db: db,
      thumbnailService: ThumbnailService(),
      pdfValidationService: const PdfValidationService(),
    );
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
    expect(score.arranger, "Busoni");
    expect(score.difficulty, 4);
    expect(score.cropExcluded, isTrue);
    expect(score.searchText, " prelude bach busoni ");
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
      arranger: "",
      partOf: "",
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
    expect(routine.progressResetAt, contentTime);
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

  test("re-importing a deleted record restores it", () async {
    await createPracticeData();
    final zip = await exportAll();

    await practiceRepo.deleteRecord(recordId);
    expect(await db.managers.deletedPracticeRecordsTable.count(), 1);

    await importFrom(zip);

    final record = await db.managers.practiceRecordsTable
        .filter((f) => f.id(recordId))
        .getSingle();
    expect(record.exercise, exerciseId);
    expect(record.routine, routineId);
    expect(record.routineEntry, routineEntryId);
    expect(record.startedAt, contentTime);
    expect(record.duration, const Duration(minutes: 7));
    expect(record.runningSince, isNull);
    expect(record.updatedAt, contentTime);
    expect(record.writtenAt, isNotNull);
    expect(record.writtenAt!.isAfter(contentTime), isTrue);
    expect(record.uploaded, isFalse);

    expect(await db.managers.deletedPracticeRecordsTable.count(), 0);
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

  test("a score of an unknown file type survives a round trip", () async {
    const futureScoreId = "score-future";
    final fileType = FileType.byName("from-the-future");
    final bytes = List<int>.generate(256, (i) => i);
    await db.managers.scoresTable.create(
      (o) => o(
        id: futureScoreId,
        title: "Chorale",
        searchText: " chorale ",
        fileDownloaded: true,
        fileType: fileType,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );
    await scoresRepo.createScoreDir(futureScoreId);
    final file = await scoresRepo.scoreFile(futureScoreId, fileType);
    expect(path.basename(file.path), "score.from-the-future");
    await file.writeAsBytes(bytes);

    final zip = await exportAll();

    await scoresRepo.deleteScore(futureScoreId);
    expect(await file.exists(), isFalse);

    await importFrom(zip);

    final score = await db.managers.scoresTable
        .filter((f) => f.id(futureScoreId))
        .getSingle();
    expect(score.fileType, fileType);
    expect(score.fileType.isKnown, isFalse);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), bytes);
  });

  test("importing a newer file keeps a colliding storage name", () async {
    const collideId = "score-collide";
    await db.managers.scoresTable.create(
      (o) => o(
        id: collideId,
        title: "Fugue",
        searchText: " fugue ",
        fileDownloaded: true,
        fileType: FileType.pdf,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );
    await scoresRepo.createScoreDir(collideId);
    final file = await scoresRepo.scoreFile(collideId, FileType.pdf);
    await file.writeAsString("%PDF-1.4 new");

    final zip = await exportAll();

    await db.managers.scoresTable
        .filter((f) => f.id(collideId))
        .update(
          (o) => o(
            fileType: Value(FileType.byName("PDF")),
            fileUpdatedAt: Value(contentTime.subtract(const Duration(days: 1))),
          ),
        );
    await file.writeAsString("%PDF-1.4 old");

    await importFrom(zip);

    final score = await db.managers.scoresTable
        .filter((f) => f.id(collideId))
        .getSingle();
    expect(score.fileType, FileType.pdf);
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), "%PDF-1.4 new");
  });

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

  test("a library larger than the open file limit round-trips", () async {
    const scoreCount = 300;
    for (var i = 0; i < scoreCount; i++) {
      final id = "bulk-$i";
      await db.managers.scoresTable.create(
        (o) => o(
          id: id,
          title: "Bulk $i",
          searchText: " bulk $i ",
          fileDownloaded: true,
          fileType: FileType.pdf,
          lastOpened: Value(contentTime),
          metadataUpdatedAt: Value(contentTime),
          fileUpdatedAt: Value(contentTime),
        ),
      );
      await scoresRepo.createScoreDir(id);
      final file = await scoresRepo.scoreFile(id, FileType.pdf);
      await file.writeAsString("%PDF-1.4 bulk $i");
    }

    final zip = await exportAll();

    await db.managers.scoresTable.delete();
    await (await scoresRepo.scoresDir).delete(recursive: true);
    await (await scoresRepo.scoresDir).create(recursive: true);

    await importFrom(zip);

    expect(await db.managers.scoresTable.count(), scoreCount + 1);
    final file = await scoresRepo.scoreFile("bulk-7", FileType.pdf);
    expect(await file.readAsString(), "%PDF-1.4 bulk 7");
  });

  test("fields cleared in a newer export are cleared on import", () async {
    final clearedAt = contentTime.add(const Duration(days: 1));
    await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            composer: const Value(null),
            source: const Value(null),
            sourceLink: const Value(null),
            notes: const Value(null),
            metadataUpdatedAt: Value(clearedAt),
          ),
        );

    final zip = await exportAll();

    await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .update(
          (o) => o(
            composer: const Value("Bach"),
            source: const Value("IMSLP"),
            sourceLink: const Value("https://imslp.org"),
            notes: const Value("slow"),
            metadataUpdatedAt: Value(contentTime),
          ),
        );

    await importFrom(zip);

    final score = await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingle();
    expect(score.metadataUpdatedAt, clearedAt);
    expect(score.composer, isNull);
    expect(score.source, isNull);
    expect(score.sourceLink, isNull);
    expect(score.notes, isNull);
  });

  test("a score without a file is left out of the export", () async {
    const missingId = "score-missing";
    await db.managers.scoresTable.create(
      (o) => o(
        id: missingId,
        title: "Missing",
        searchText: " missing ",
        fileDownloaded: true,
        fileType: FileType.pdf,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );

    final zip = await exportAll();
    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    final scoresJson = String.fromCharCodes(
      archive.findFile("scores.json")!.content,
    );
    expect(scoresJson, isNot(contains(missingId)));
    expect(scoresJson, contains(scoreId));
  });

  test("a repacked archive with unusual entry names imports", () async {
    final archive = ZipDecoder().decodeBytes(
      await File(await exportAll()).readAsBytes(),
    );
    final repacked = Archive();
    for (final f in archive) {
      repacked.add(
        f.isFile
            ? ArchiveFile.bytes("./${f.name}", f.content)
            : ArchiveFile.directory("./${f.name}"),
      );
    }
    final bytes = ZipEncoder().encode(repacked);
    final from = "scores/$scoreId/".codeUnits;
    final to = "scores\\$scoreId\\".codeUnits;
    for (var i = 0; i <= bytes.length - from.length; i++) {
      var match = true;
      for (var j = 0; j < from.length && match; j++) {
        match = bytes[i + j] == from[j];
      }
      if (match) bytes.setRange(i, i + to.length, to);
    }
    final zip = path.join(exportDir.path, "repacked.zip");
    await File(zip).writeAsBytes(bytes);

    await db.managers.setlistsTable.delete();
    await db.managers.scoresTable.delete();
    await (await scoresRepo.scoresDir).delete(recursive: true);
    await (await scoresRepo.scoresDir).create(recursive: true);

    await importFrom(zip);

    final ids = await db.managers.scoresTable.map((s) => s.id).get();
    expect(ids, [scoreId]);
    final file = await scoresRepo.scoreFile(scoreId, FileType.pdf);
    expect(await file.readAsString(), "%PDF-1.4 fake");
  });

  test("a score missing its file in the archive is skipped", () async {
    const otherId = "score-other";
    await db.managers.scoresTable.create(
      (o) => o(
        id: otherId,
        title: "Other",
        searchText: " other ",
        fileDownloaded: true,
        fileType: FileType.pdf,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
      ),
    );
    await scoresRepo.createScoreDir(otherId);
    await (await scoresRepo.scoreFile(
      otherId,
      FileType.pdf,
    )).writeAsString("%PDF-1.4 other");

    final zip = await exportAll();
    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    final stripped = Archive();
    for (final f in archive) {
      if (!f.name.startsWith("scores/$scoreId/")) stripped.add(f);
    }
    final strippedPath = path.join(exportDir.path, "stripped.zip");
    await File(strippedPath).writeAsBytes(ZipEncoder().encode(stripped));

    await db.managers.setlistsTable.delete();
    await db.managers.scoresTable.delete();
    await (await scoresRepo.scoresDir).delete(recursive: true);
    await (await scoresRepo.scoresDir).create(recursive: true);

    await importFrom(strippedPath);

    final ids = await db.managers.scoresTable.map((s) => s.id).get();
    expect(ids, [otherId]);
    expect(await db.managers.setlistsTable.count(), 1);
  });

  test("an import stages nothing outside the scores dir", () async {
    final zip = await exportAll();
    await scoresRepo.deleteScore(scoreId);

    final before = tempDir.listSync().map((e) => e.path).toSet();
    await importFrom(zip);
    final after = tempDir.listSync().map((e) => e.path).toSet();

    expect(after, before);
    final scoresDir = await scoresRepo.scoresDir;
    final leftovers = scoresDir
        .listSync(recursive: true)
        .where((e) => e.path.endsWith(".part"));
    expect(leftovers, isEmpty);
    final file = await scoresRepo.scoreFile(scoreId, FileType.pdf);
    expect(await file.readAsString(), "%PDF-1.4 fake");
  });

  test("the marker file is the last entry of an export", () async {
    final archive = ZipDecoder().decodeBytes(
      await File(await exportAll()).readAsBytes(),
    );
    expect(archive.files.last.name, ".sheetopia");
    expect(archive.files.where((f) => f.name == ".sheetopia"), hasLength(1));
  });

  test("a zip without the marker file is rejected", () async {
    final archive = Archive()
      ..add(ArchiveFile.bytes("tags.json", "[]".codeUnits))
      ..add(ArchiveFile.bytes("scores.json", "[]".codeUnits));
    final zip = path.join(exportDir.path, "foreign.zip");
    await File(zip).writeAsBytes(ZipEncoder().encode(archive));

    fileSelector.fileToOpen = zip;
    await expectLater(repo.import(), throwsA(isA<InvalidFileException>()));
    expect(repo.status, ImportExportStatus.idle);
  });

  for (final (name, json) in [
    ("an object", "{}"),
    ("a list of non objects", "[1]"),
    ("an entry missing a field", '[{"id": "a"}]'),
  ]) {
    test("a scores.json holding $name is rejected", () async {
      final archive = Archive()
        ..add(ArchiveFile.bytes("tags.json", "[]".codeUnits))
        ..add(ArchiveFile.bytes("scores.json", json.codeUnits))
        ..add(ArchiveFile.bytes(".sheetopia", const []));
      final zip = path.join(exportDir.path, "malformed.zip");
      await File(zip).writeAsBytes(ZipEncoder().encode(archive));

      fileSelector.fileToOpen = zip;
      await expectLater(repo.import(), throwsA(isA<InvalidFileException>()));
      expect(repo.status, ImportExportStatus.idle);
    });
  }

  test("a file that is not a zip is rejected", () async {
    final zip = path.join(exportDir.path, "broken.zip");
    await File(zip).writeAsString("not a zip");

    fileSelector.fileToOpen = zip;
    await expectLater(repo.import(), throwsA(isA<InvalidFileException>()));
  });

  test("a truncated zip is rejected", () async {
    final bytes = await File(await exportAll()).readAsBytes();
    final zip = path.join(exportDir.path, "truncated.zip");
    await File(zip).writeAsBytes(bytes.sublist(0, bytes.length - 30));

    fileSelector.fileToOpen = zip;
    await expectLater(repo.import(), throwsA(isA<InvalidFileException>()));
  });

  test("a score id unusable as a path rejects the whole archive", () async {
    final archive = ZipDecoder().decodeBytes(
      await File(await exportAll()).readAsBytes(),
    );
    final scoresJson = String.fromCharCodes(
      archive.findFile("scores.json")!.content,
    );
    final tampered = Archive();
    for (final f in archive) {
      if (f.name == "scores.json") {
        tampered.add(
          ArchiveFile.bytes(
            "scores.json",
            scoresJson.replaceAll(scoreId, "../evil").codeUnits,
          ),
        );
      } else {
        tampered.add(f);
      }
    }
    final zip = path.join(exportDir.path, "tampered.zip");
    await File(zip).writeAsBytes(ZipEncoder().encode(tampered));

    await scoresRepo.deleteTag(tagId);

    fileSelector.fileToOpen = zip;
    await expectLater(repo.import(), throwsA(isA<InvalidFileException>()));
    expect(await db.managers.tagsTable.count(), 0);
  });

  test(
    "the archive reader reports a missing entry and keeps working",
    () async {
      final zip = await exportAll();
      final reader = await ArchiveReader.open(zip);
      try {
        final target = path.join(tempDir.path, "extracted.pdf");
        await expectLater(
          reader.extract("scores/nope/score.pdf", target),
          throwsA(isA<PathNotFoundException>()),
        );
        expect(await File(target).exists(), isFalse);

        await reader.extract("scores/$scoreId/score.pdf", target);
        expect(await File(target).readAsString(), "%PDF-1.4 fake");
      } finally {
        await reader.close();
      }
    },
  );

  test("a failed export keeps the file it would have replaced", () async {
    final target = path.join(exportDir.path, "export.zip");
    await File(target).writeAsString("old backup");
    final scoreFile = await scoresRepo.scoreFile(scoreId, FileType.pdf);
    await Process.run("chmod", ["000", scoreFile.path]);
    addTearDown(() => Process.run("chmod", ["644", scoreFile.path]));

    fileSelector.saveLocation = target;
    await expectLater(repo.export(), throwsA(anything));

    expect(await File(target).readAsString(), "old backup");
    expect(await File("$target.part").exists(), isFalse);
    expect(repo.status, ImportExportStatus.idle);
  }, skip: !Platform.isLinux && !Platform.isMacOS);

  test("an export works when only the chosen file is writable", () async {
    final dir = await Directory(path.join(exportDir.path, "locked")).create();
    final target = path.join(dir.path, "export.zip");
    await File(target).writeAsString("old backup");
    await Process.run("chmod", ["555", dir.path]);
    addTearDown(() => Process.run("chmod", ["755", dir.path]));

    fileSelector.saveLocation = target;
    expect(await repo.export(), isTrue);

    final archive = ZipDecoder().decodeBytes(await File(target).readAsBytes());
    expect(archive.findFile("scores/$scoreId/score.pdf"), isNotNull);
    expect(await dir.list().map((e) => e.path).toList(), [target]);
    expect(repo.status, ImportExportStatus.idle);
  }, skip: !Platform.isLinux && !Platform.isMacOS);
}
