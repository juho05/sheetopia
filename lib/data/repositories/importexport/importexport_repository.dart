/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/importexport/archive_reader.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/datetime_converter.dart';
import 'package:sheetopia/data/services/sync/models/exercise_categories.dart';
import 'package:sheetopia/data/services/sync/models/exercise_metadata.dart';
import 'package:sheetopia/data/services/sync/models/exercises.dart';
import 'package:sheetopia/data/services/sync/models/optional_values.dart';
import 'package:sheetopia/data/services/sync/models/practice_records.dart';
import 'package:sheetopia/data/services/sync/models/practice_routines.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/utils/file_export.dart';
import 'package:sheetopia/utils/id_path.dart';

enum ImportExportStatus { idle, importing, exporting }

typedef _ArchiveData = ({
  List<TagModel> tags,
  List<ScoreModel> scores,
  List<SetlistModel> setlists,
  List<ExerciseCategoryModel> categories,
  List<ExerciseModel> exercises,
  List<PracticeRoutineModel> routines,
  List<PracticeRecordModel> records,
  Set<String> fileNames,
});

class InvalidFileException implements Exception {
  final String message;

  InvalidFileException(this.message);

  @override
  String toString() {
    return "InvalidFileException: $message";
  }
}

class ImportExportRepository extends ChangeNotifier {
  final SyncRepository _syncRepo;
  final ScoresRepository _scoresRepo;
  final SetlistsRepository _setlistsRepo;
  final PracticeRepository _practiceRepo;
  final ThumbnailService _thumbnailService;
  final Database _db;

  final StreamController<void> _importedStream = StreamController.broadcast();

  Stream<void> get importedStream => _importedStream.stream;

  final zipTypeGroup = const XTypeGroup(
    label: "ZIP",
    extensions: [".zip"],
    mimeTypes: ["application/zip"],
    uniformTypeIdentifiers: ["public.zip-archive"],
  );

  ImportExportStatus _status = ImportExportStatus.idle;

  ImportExportStatus get status => _status;

  ImportExportRepository({
    required this._scoresRepo,
    required this._setlistsRepo,
    required this._practiceRepo,
    required this._syncRepo,
    required this._db,
    required this._thumbnailService,
  });

  Set<String> _changedScores = {};
  Set<String> _changedTags = {};
  Set<String> _changedSetlists = {};
  Set<String> _changedCategories = {};
  Set<String> _changedExercises = {};
  Set<String> _changedRoutines = {};

  Set<String> _changedRecords = {};

  Future<bool> import({void Function()? onSelected}) async {
    if (_status != ImportExportStatus.idle) {
      throw Exception("Cannot start export when alreading importing/exporting");
    }
    _status = ImportExportStatus.importing;
    notifyListeners();

    try {
      final XFile? zipFile = await openFile(
        acceptedTypeGroups: <XTypeGroup>[zipTypeGroup],
      );
      if (zipFile == null) return false;

      try {
        final extension = path.extension(zipFile.path);
        if (extension != ".zip") {
          throw InvalidFileException("invalid file extension: $extension");
        }

        onSelected?.call();

        final reader = await ArchiveReader.open(zipFile.path);
        try {
          final _ArchiveData data;
          try {
            data = await reader.run(_readArchive);
          } on FormatException catch (e) {
            throw InvalidFileException(e.toString());
          }
          final importedAt = DateTime.now().toUtc();

          await _importTags(data.tags, importedAt);
          await _importScores(data.scores, reader, data.fileNames, importedAt);
          await _importSetlists(data.setlists, importedAt);
          await _importExerciseCategories(data.categories, importedAt);
          await _importExercises(data.exercises, importedAt);
          await _importPracticeRoutines(data.routines, importedAt);
          await _importPracticeRecords(data.records, importedAt);
        } finally {
          await reader.close();
        }
      } finally {
        if (Platform.isAndroid) {
          await _deletePickerCopy(zipFile, await getTemporaryDirectory());
        }
      }
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _scoresRepo.requestProcessing(_changedScores);
      _setlistsRepo.remoteChangedSetlists(_changedSetlists);
      _practiceRepo.remoteChangedCategories(_changedCategories);
      _practiceRepo.remoteChangedExercises(_changedExercises);
      _practiceRepo.remoteChangedRoutines(_changedRoutines);
      _practiceRepo.remoteChangedRecords(_changedRecords);
      _changedScores = {};
      _changedTags = {};
      _changedSetlists = {};
      _changedCategories = {};
      _changedExercises = {};
      _changedRoutines = {};
      _changedRecords = {};
      _status = ImportExportStatus.idle;
      notifyListeners();
      _syncRepo.requestSync();
    }

    return true;
  }

  Future<bool> export({Rect? sharePositionOrigin}) async {
    if (_status != ImportExportStatus.idle) {
      throw Exception("Cannot start export when alreading importing/exporting");
    }
    _status = ImportExportStatus.exporting;
    notifyListeners();

    try {
      final tempDir = await getTemporaryDirectory();
      final tempExportDir = await tempDir.createTemp("sheetopia-export-");
      final scoreFiles = <String, String>{};

      try {
        {
          final tags = await _scoresRepo.getTags();
          final tagModels = tags
              .map(
                (t) => TagModel(
                  id: t.id,
                  name: t.name,
                  color: t.color.toARGB32(),
                  type: t.type,
                  updatedAt: t.updatedAt.toUtc(),
                ),
              )
              .toList();
          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "tags.json",
            "models": tagModels,
          });
        }

        {
          final scoreModels = <ScoreModel>[];

          int offset = 0;
          while (true) {
            final scores = await _scoresRepo.getScores(
              size: 500,
              offset: offset,
            );
            for (final s in scores) {
              if (s.file == null) continue;
              if (!await s.file!.exists()) {
                Log.warn("Skipping score ${s.id} without file in export");
                continue;
              }
              scoreFiles[path.posix.join(
                    "scores",
                    s.id,
                    path.basename(s.file!.path),
                  )] =
                  s.file!.path;
              scoreModels.add(
                ScoreModel(
                  id: s.id,
                  title: s.title,
                  fileType: s.fileType,
                  fileUpdatedAt: s.fileUpdatedAt,
                  metadata: ScoreMetadataModel(
                    composer: s.composer ?? "",
                    arranger: s.arranger ?? "",
                    partOf: s.partOf ?? "",
                    musicalKey: s.musicalKey?.name ?? "",
                    source: s.source ?? "",
                    sourceLink: s.sourceLink ?? "",
                    genres: s.genres,
                    instruments: s.instruments,
                    notes: s.notes ?? "",
                    difficulty: s.difficulty?.level ?? 0,
                    annotations: s.annotations == null
                        ? {}
                        : jsonDecode(s.annotations!) as Map<String, dynamic>,
                    cropExcluded: s.cropExcluded,
                  ),
                  metadataUpdatedAt: s.metadataUpdatedAt,
                  tagIds: s.tags.map((t) => t.id).toList(),
                  type: s.type,
                ),
              );
            }
            if (scores.length < 500) break;
            offset += scores.length;
          }

          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "scores.json",
            "models": scoreModels,
          });
        }

        {
          final setlistModels = <SetlistModel>[];
          for (final s in await _setlistsRepo.getSetlists()) {
            final full = await _setlistsRepo.getSetlist(s.id);
            if (full == null) continue;
            setlistModels.add(
              SetlistModel(
                id: full.id,
                name: full.name,
                scoreIds: full.entries.map((e) => e.scoreId).toList(),
                updatedAt: full.updatedAt.toUtc(),
              ),
            );
          }
          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "setlists.json",
            "models": setlistModels,
          });
        }

        {
          final categories = await _db.managers.exerciseCategoriesTable.get();
          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "exercise_categories.json",
            "models": [
              for (final c in categories)
                ExerciseCategoryModel(
                  id: c.id,
                  name: c.name,
                  position: c.position,
                  updatedAt: c.updatedAt.toUtc(),
                ),
            ],
          });
        }

        {
          final exercises = await _db.managers.exercisesTable.get();

          final tagIds = <String, List<String>>{};
          for (final t in await _db.managers.exerciseTagsTable.get()) {
            tagIds.putIfAbsent(t.exercise, () => []).add(t.tag);
          }

          final scoreIds = <String, List<String>>{};
          final exerciseScores = await (_db.select(
            _db.exerciseScoresTable,
          )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
          for (final s in exerciseScores) {
            scoreIds.putIfAbsent(s.exercise, () => []).add(s.score);
          }

          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "exercises.json",
            "models": [
              for (final e in exercises)
                ExerciseModel(
                  id: e.id,
                  name: e.name,
                  categoryId: e.category,
                  tagIds: tagIds[e.id] ?? [],
                  scoreIds: scoreIds[e.id] ?? [],
                  metadata: ExerciseMetadataModel(
                    description: e.description ?? "",
                    source: e.source ?? "",
                    sourceLink: e.sourceLink ?? "",
                    instrument: e.instrument ?? "",
                    difficulty: e.difficulty ?? 0,
                    targetBpm: e.targetBpm ?? 0,
                    progressResetAt: e.progressResetAt?.toRFC3339() ?? "",
                  ),
                  updatedAt: e.updatedAt.toUtc(),
                ),
            ],
          });
        }

        {
          final routines = await _db.managers.practiceRoutinesTable.get();

          final entries = <String, List<PracticeRoutineEntryModel>>{};
          final routineEntries = await (_db.select(
            _db.practiceRoutineEntriesTable,
          )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
          for (final e in routineEntries) {
            entries
                .putIfAbsent(e.routine, () => [])
                .add(
                  PracticeRoutineEntryModel(
                    id: e.id,
                    exerciseId: e.exercise,
                    metadata: PracticeRoutineEntryMetadataModel(
                      extraNotes: e.extraNotes ?? "",
                      defaultScoreId: e.defaultScore ?? "",
                      targetDuration: e.targetDuration?.inMilliseconds ?? 0,
                    ),
                  ),
                );
          }

          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "practice_routines.json",
            "models": [
              for (final r in routines)
                PracticeRoutineModel(
                  id: r.id,
                  name: r.name,
                  metadata: PracticeRoutineMetadataModel(
                    description: r.description ?? "",
                    progressResetAt: r.progressResetAt?.toRFC3339() ?? "",
                  ),
                  entries: entries[r.id] ?? [],
                  updatedAt: r.updatedAt.toUtc(),
                ),
            ],
          });
        }

        {
          final records = await _db.managers.practiceRecordsTable.get();
          await compute(_saveJson, {
            "dir": tempExportDir.path,
            "fileName": "practice_records.json",
            "models": [
              for (final r in records)
                PracticeRecordModel(
                  id: r.id,
                  exerciseId: r.exercise,
                  routineId: r.routine,
                  routineEntryId: r.routineEntry,
                  metadata: PracticeRecordMetadataModel(
                    duration: r.duration.inMilliseconds,
                    startedAt: r.startedAt.toUtc(),
                  ),
                  updatedAt: r.updatedAt.toUtc(),
                ),
            ],
          });
        }

        final fileName =
            "sheetopia-export-${DateFormat("yyyy-MM-dd_HH-mm-ss").format(DateTime.now())}.zip";

        if (!Platform.isAndroid && !Platform.isIOS) {
          final result = await getSaveLocation(
            suggestedName: fileName,
            acceptedTypeGroups: [zipTypeGroup],
            canCreateDirectories: true,
          );
          if (result == null) return false;

          Directory? stagingDir;
          File staging;
          try {
            staging = await File("${result.path}.part").create();
          } on FileSystemException {
            // sandboxed save dialogs may only grant access to the chosen file
            stagingDir = await tempDir.createTemp();
            staging = File(path.join(stagingDir.path, fileName));
          }
          try {
            await compute(_createZipFile, {
              "dir": tempExportDir.path,
              "files": scoreFiles,
              "path": staging.path,
            });
            if (stagingDir == null) {
              await staging.rename(result.path);
            } else {
              await staging.copy(result.path);
            }
          } catch (_) {
            if (stagingDir == null) {
              try {
                await staging.delete();
              } catch (_) {}
            }
            rethrow;
          } finally {
            await stagingDir?.delete(recursive: true);
          }
          return true;
        }

        final zipFileDir = await tempDir.createTemp();

        try {
          final zipFile = File(path.join(zipFileDir.path, fileName));

          await compute(_createZipFile, {
            "dir": tempExportDir.path,
            "files": scoreFiles,
            "path": zipFile.path,
          });

          await tempExportDir.delete(recursive: true);

          if (Platform.isAndroid) {
            return await exportFileMobile(
              path: zipFile.path,
              fileName: fileName,
              mimeType: "application/zip",
            );
          }

          final result = await SharePlus.instance.share(
            ShareParams(
              title: "Export scores",
              fileNameOverrides: [fileName],
              files: [
                XFile(
                  zipFile.path,
                  name: fileName,
                  mimeType: "application/zip",
                ),
              ],
              sharePositionOrigin: sharePositionOrigin,
            ),
          );
          return result.status != ShareResultStatus.dismissed;
        } finally {
          await zipFileDir.delete(recursive: true);
        }
      } finally {
        if (tempExportDir.existsSync()) {
          await tempExportDir.delete(recursive: true);
        }
      }
    } finally {
      _status = ImportExportStatus.idle;
      notifyListeners();
    }
  }

  Future<void> _importTags(List<TagModel> tags, DateTime importedAt) async {
    await _dropPendingTombstones(
      tags.map((t) => t.id).toList(),
      (chunk) => _db.managers.deletedTagsTable
          .filter((f) => f.tagId.isIn(chunk))
          .delete(),
    );

    for (final t in tags) {
      final result = await _db.managers.tagsTable.createReturningOrNull(
        (o) => o(
          id: t.id,
          name: t.name,
          color: t.color,
          type: t.type != null ? Value(t.type!) : const Value.absent(),
          updatedAt: Value(t.updatedAt.toUtc()),
          writtenAt: Value(importedAt),
          uploaded: const Value(false),
        ),
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => TagsTableCompanion.custom(
            name: excluded.name,
            color: excluded.color,
            type: t.type != null ? excluded.type : null,
            uploaded: excluded.uploaded,
            updatedAt: excluded.updatedAt,
            writtenAt: excluded.writtenAt,
          ),
          where: (old, excluded) =>
              old.updatedAt.isSmallerThan(excluded.updatedAt),
        ),
      );
      if (result != null) {
        _changedTags.add(t.id);
        final affectedScores = await _db.managers.scoreTagsTable
            .filter((f) => f.tag.id(t.id))
            .map((s) => s.score)
            .get();
        _changedScores.addAll(affectedScores);
      }
    }
  }

  Future<List<String>> _knownTagIds(String owner, List<String> tagIds) async {
    final known =
        (await _db.managers.tagsTable
                .filter((f) => f.id.isIn(tagIds))
                .map((t) => t.id)
                .get())
            .toSet();
    final unknown = tagIds.where((t) => !known.contains(t));
    if (unknown.isNotEmpty) {
      Log.warn("Dropping unknown tags ${unknown.join(", ")} of $owner");
    }
    return tagIds.where(known.contains).toList();
  }

  Future<void> _dropPendingTombstones(
    List<String> ids,
    Future<void> Function(List<String> chunk) deleteChunk,
  ) async {
    const chunkSize = 500;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final end = i + chunkSize;
      await deleteChunk(ids.sublist(i, end > ids.length ? ids.length : end));
    }
  }

  Future<void> _importSetlists(
    List<SetlistModel> setlists,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      setlists.map((s) => s.id).toList(),
      (chunk) => _db.managers.deletedSetlistsTable
          .filter((f) => f.setlistId.isIn(chunk))
          .delete(),
    );

    for (final s in setlists) {
      await _db.transaction(() async {
        final result = await _db.managers.setlistsTable.createReturningOrNull(
          (o) => o(
            id: s.id,
            name: s.name,
            updatedAt: Value(s.updatedAt.toUtc()),
            writtenAt: Value(importedAt),
            uploaded: const Value(false),
          ),
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => SetlistsTableCompanion.custom(
              name: excluded.name,
              uploaded: excluded.uploaded,
              updatedAt: excluded.updatedAt,
              writtenAt: excluded.writtenAt,
            ),
            where: (old, excluded) =>
                old.updatedAt.isSmallerThan(excluded.updatedAt),
          ),
        );
        if (result == null) return;
        await _db.managers.setlistEntriesTable
            .filter((f) => f.setlist.id(s.id))
            .delete();
        await _db.managers.setlistEntriesTable.bulkCreate(
          (o) => s.scoreIds.indexed.map(
            (e) => o(setlist: s.id, score: e.$2, position: e.$1),
          ),
        );
        _changedSetlists.add(s.id);
      });
    }
  }

  Future<void> _importExerciseCategories(
    List<ExerciseCategoryModel> categories,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      categories.map((c) => c.id).toList(),
      (chunk) => _db.managers.deletedExerciseCategoriesTable
          .filter((f) => f.categoryId.isIn(chunk))
          .delete(),
    );

    for (final c in categories) {
      final result = await _db.managers.exerciseCategoriesTable
          .createReturningOrNull(
            (o) => o(
              id: c.id,
              name: c.name,
              position: c.position,
              updatedAt: Value(c.updatedAt.toUtc()),
              writtenAt: Value(importedAt),
              uploaded: const Value(false),
            ),
            onConflict: DoUpdate.withExcluded(
              (old, excluded) => ExerciseCategoriesTableCompanion.custom(
                name: excluded.name,
                position: excluded.position,
                uploaded: excluded.uploaded,
                updatedAt: excluded.updatedAt,
                writtenAt: excluded.writtenAt,
              ),
              where: (old, excluded) =>
                  old.updatedAt.isSmallerThan(excluded.updatedAt),
            ),
          );
      if (result != null) _changedCategories.add(c.id);
    }
  }

  Future<void> _importExercises(
    List<ExerciseModel> exercises,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      exercises.map((e) => e.id).toList(),
      (chunk) => _db.managers.deletedExercisesTable
          .filter((f) => f.exerciseId.isIn(chunk))
          .delete(),
    );

    for (final e in exercises) {
      await _db.transaction(() async {
        final categoryId = await _knownCategoryId(e.id, e.categoryId);
        final result = await _db.managers.exercisesTable.createReturningOrNull(
          (o) => o(
            id: e.id,
            name: e.name,
            category: Value(categoryId),
            description: optionalStringValue(e.metadata.description),
            source: optionalStringValue(e.metadata.source),
            sourceLink: optionalStringValue(e.metadata.sourceLink),
            instrument: optionalStringValue(e.metadata.instrument),
            difficulty: optionalIntValue(e.metadata.difficulty),
            targetBpm: optionalIntValue(e.metadata.targetBpm),
            progressResetAt: optionalDateTimeValue(e.metadata.progressResetAt),
            updatedAt: Value(e.updatedAt.toUtc()),
            writtenAt: Value(importedAt),
            uploaded: const Value(false),
          ),
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => ExercisesTableCompanion.custom(
              name: excluded.name,
              category: excluded.category,
              description: e.metadata.description != null
                  ? excluded.description
                  : null,
              source: e.metadata.source != null ? excluded.source : null,
              sourceLink: e.metadata.sourceLink != null
                  ? excluded.sourceLink
                  : null,
              instrument: e.metadata.instrument != null
                  ? excluded.instrument
                  : null,
              difficulty: e.metadata.difficulty != null
                  ? excluded.difficulty
                  : null,
              targetBpm: e.metadata.targetBpm != null
                  ? excluded.targetBpm
                  : null,
              progressResetAt: e.metadata.progressResetAt != null
                  ? excluded.progressResetAt
                  : null,
              uploaded: excluded.uploaded,
              updatedAt: excluded.updatedAt,
              writtenAt: excluded.writtenAt,
            ),
            where: (old, excluded) =>
                old.updatedAt.isSmallerThan(excluded.updatedAt),
          ),
        );
        if (result == null) return;

        await _db.managers.exerciseTagsTable
            .filter((f) => f.exercise.id(e.id))
            .delete();
        final tagIds = await _knownTagIds("exercise ${e.id}", e.tagIds);
        if (tagIds.isNotEmpty) {
          await _db.managers.exerciseTagsTable.bulkCreate(
            (o) => tagIds.map((t) => o(exercise: e.id, tag: t)),
          );
        }

        await _db.managers.exerciseScoresTable
            .filter((f) => f.exercise.id(e.id))
            .delete();
        if (e.scoreIds.isNotEmpty) {
          await _db.managers.exerciseScoresTable.bulkCreate(
            (o) => e.scoreIds.indexed.map(
              (s) => o(exercise: e.id, score: s.$2, position: s.$1),
            ),
          );
        }

        _changedExercises.add(e.id);
      });
    }
  }

  Future<String?> _knownCategoryId(
    String exerciseId,
    String? categoryId,
  ) async {
    if (categoryId == null) return null;
    final category = await _db.managers.exerciseCategoriesTable
        .filter((f) => f.id(categoryId))
        .getSingleOrNull();
    if (category != null) return categoryId;
    Log.warn("Dropping unknown category $categoryId of exercise $exerciseId");
    return null;
  }

  Future<void> _importPracticeRoutines(
    List<PracticeRoutineModel> routines,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      routines.map((r) => r.id).toList(),
      (chunk) => _db.managers.deletedPracticeRoutinesTable
          .filter((f) => f.routineId.isIn(chunk))
          .delete(),
    );

    for (final r in routines) {
      await _db.transaction(() async {
        final result = await _db.managers.practiceRoutinesTable
            .createReturningOrNull(
              (o) => o(
                id: r.id,
                name: r.name,
                description: optionalStringValue(r.metadata.description),
                progressResetAt: optionalDateTimeValue(
                  r.metadata.progressResetAt,
                ),
                updatedAt: Value(r.updatedAt.toUtc()),
                writtenAt: Value(importedAt),
                uploaded: const Value(false),
              ),
              onConflict: DoUpdate.withExcluded(
                (old, excluded) => PracticeRoutinesTableCompanion.custom(
                  name: excluded.name,
                  description: r.metadata.description != null
                      ? excluded.description
                      : null,
                  progressResetAt: r.metadata.progressResetAt != null
                      ? excluded.progressResetAt
                      : null,
                  uploaded: excluded.uploaded,
                  updatedAt: excluded.updatedAt,
                  writtenAt: excluded.writtenAt,
                ),
                where: (old, excluded) =>
                    old.updatedAt.isSmallerThan(excluded.updatedAt),
              ),
            );
        if (result == null) return;

        await _db.managers.practiceRoutineEntriesTable
            .filter((f) => f.routine.id(r.id))
            .delete();
        final entries = await _knownExerciseEntries(r.id, r.entries);
        if (entries.isNotEmpty) {
          await _db.managers.practiceRoutineEntriesTable.bulkCreate(
            (o) => entries.indexed.map(
              (e) => o(
                id: e.$2.id,
                routine: r.id,
                exercise: e.$2.exerciseId,
                position: e.$1,
                extraNotes: optionalStringValue(e.$2.metadata.extraNotes),
                defaultScore: optionalStringValue(e.$2.metadata.defaultScoreId),
                targetDuration: optionalDurationValue(
                  e.$2.metadata.targetDuration,
                ),
              ),
            ),
          );
        }
        _changedRoutines.add(r.id);
      });
    }
  }

  Future<List<PracticeRoutineEntryModel>> _knownExerciseEntries(
    String routineId,
    List<PracticeRoutineEntryModel> entries,
  ) async {
    if (entries.isEmpty) return entries;
    final known =
        (await _db.managers.exercisesTable
                .filter((f) => f.id.isIn(entries.map((e) => e.exerciseId)))
                .map((e) => e.id)
                .get())
            .toSet();
    final unknown = entries
        .where((e) => !known.contains(e.exerciseId))
        .map((e) => e.exerciseId);
    if (unknown.isNotEmpty) {
      Log.warn(
        "Dropping entries of unknown exercises ${unknown.join(", ")} of practice routine $routineId",
      );
    }
    return entries.where((e) => known.contains(e.exerciseId)).toList();
  }

  Future<void> _importPracticeRecords(
    List<PracticeRecordModel> records,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      records.map((r) => r.id).toList(),
      (chunk) => _db.managers.deletedPracticeRecordsTable
          .filter((f) => f.recordId.isIn(chunk))
          .delete(),
    );

    for (final r in records) {
      final duration = r.metadata.duration;
      final startedAt = r.metadata.startedAt;
      final result = await _db.managers.practiceRecordsTable
          .createReturningOrNull(
            (o) => o(
              id: r.id,
              exercise: r.exerciseId,
              routine: Value(r.routineId),
              routineEntry: Value(r.routineEntryId),
              startedAt: (startedAt ?? r.updatedAt).toUtc(),
              duration: Value(Duration(milliseconds: duration ?? 0)),
              updatedAt: Value(r.updatedAt.toUtc()),
              writtenAt: Value(importedAt),
              uploaded: const Value(false),
            ),
            onConflict: DoUpdate.withExcluded(
              (old, excluded) => PracticeRecordsTableCompanion.custom(
                exercise: excluded.exercise,
                routine: excluded.routine,
                routineEntry: excluded.routineEntry,
                startedAt: startedAt != null ? excluded.startedAt : null,
                duration: duration != null ? excluded.duration : null,
                uploaded: excluded.uploaded,
                updatedAt: excluded.updatedAt,
                writtenAt: excluded.writtenAt,
              ),
              where: (old, excluded) =>
                  old.updatedAt.isSmallerThan(excluded.updatedAt),
            ),
          );
      if (result != null) _changedRecords.add(r.id);
    }
  }

  Future<void> _importScores(
    List<ScoreModel> scores,
    ArchiveReader reader,
    Set<String> fileNames,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      scores.map((s) => s.id).toList(),
      (chunk) => _db.managers.deletedScoresTable
          .filter((f) => f.scoreId.isIn(chunk))
          .delete(),
    );

    for (final s in scores) {
      File? deleteFile;
      await _db.transaction(() async {
        final score = await _db.managers.scoresTable
            .filter((f) => f.id(s.id))
            .getSingleOrNull();

        final metadataChanged =
            score != null &&
            score.metadataUpdatedAt.isBefore(s.metadataUpdatedAt);
        var fileChanged =
            score != null && score.fileUpdatedAt.isBefore(s.fileUpdatedAt);

        final entryName =
            "scores/${idSegment(s.id)}/score${fileTypeExtension(s.fileType)}";
        if ((score == null || fileChanged) && !fileNames.contains(entryName)) {
          Log.warn("Missing file for score ${s.id} in import");
          if (score == null) return;
          fileChanged = false;
        }

        if (score == null || fileChanged) {
          await _scoresRepo.createScoreDir(s.id);
          final targetScoreFile = await _scoresRepo.scoreFile(s.id, s.fileType);
          try {
            await reader.extract(entryName, targetScoreFile.path);
          } on FormatException catch (e) {
            throw InvalidFileException(e.toString());
          }
          await _thumbnailService.invalidateThumbnails({s.id});

          if (score != null &&
              fileTypeExtension(score.fileType) !=
                  fileTypeExtension(s.fileType)) {
            deleteFile = await _scoresRepo.scoreFile(score.id, score.fileType);
          }
        }

        if (score == null) {
          await _db.managers.scoresTable.create(
            (o) => o(
              id: s.id,
              searchText: ScoresRepository.generateSearchText([
                s.title,
                s.metadata.composer,
                s.metadata.arranger,
                s.metadata.partOf,
              ]),
              title: s.title,
              composer: optionalStringValue(s.metadata.composer),
              arranger: optionalStringValue(s.metadata.arranger),
              partOf: optionalStringValue(s.metadata.partOf),
              musicalKey: optionalStringValue(s.metadata.musicalKey),
              source: optionalStringValue(s.metadata.source),
              sourceLink: optionalStringValue(s.metadata.sourceLink),
              notes: optionalStringValue(s.metadata.notes),
              difficulty: optionalIntValue(s.metadata.difficulty),
              annotations: _annotationsColumnValue(s.metadata.annotations),
              cropExcluded: optionalBoolValue(s.metadata.cropExcluded),
              metadataUploaded: const Value(false),
              metadataUpdatedAt: Value(s.metadataUpdatedAt.toUtc()),
              writtenAt: Value(importedAt),
              lastOpened: Value(
                s.metadataUpdatedAt.isAfter(s.fileUpdatedAt)
                    ? s.metadataUpdatedAt.toUtc()
                    : s.fileUpdatedAt.toUtc(),
              ),
              fileType: s.fileType,
              fileUpdatedAt: Value(s.fileUpdatedAt.toUtc()),
              fileDownloaded: true,
              fileUploaded: const Value(false),
              type: s.type != null ? Value(s.type!) : const Value.absent(),
            ),
          );
        } else if (metadataChanged || fileChanged) {
          await _db.managers.scoresTable
              .filter((f) => f.id(s.id))
              .update(
                (o) => o(
                  title: metadataChanged
                      ? Value(s.title)
                      : const Value.absent(),
                  metadataUpdatedAt: metadataChanged
                      ? Value(s.metadataUpdatedAt.toUtc())
                      : const Value.absent(),
                  metadataUploaded: metadataChanged
                      ? const Value(false)
                      : const Value.absent(),
                  writtenAt: Value(importedAt),
                  composer: metadataChanged
                      ? optionalStringValue(s.metadata.composer)
                      : const Value.absent(),
                  arranger: metadataChanged
                      ? optionalStringValue(s.metadata.arranger)
                      : const Value.absent(),
                  partOf: metadataChanged
                      ? optionalStringValue(s.metadata.partOf)
                      : const Value.absent(),
                  musicalKey: metadataChanged
                      ? optionalStringValue(s.metadata.musicalKey)
                      : const Value.absent(),
                  source: metadataChanged
                      ? optionalStringValue(s.metadata.source)
                      : const Value.absent(),
                  sourceLink: metadataChanged
                      ? optionalStringValue(s.metadata.sourceLink)
                      : const Value.absent(),
                  notes: metadataChanged
                      ? optionalStringValue(s.metadata.notes)
                      : const Value.absent(),
                  difficulty: metadataChanged
                      ? optionalIntValue(s.metadata.difficulty)
                      : const Value.absent(),
                  annotations: metadataChanged
                      ? _annotationsColumnValue(s.metadata.annotations)
                      : const Value.absent(),
                  cropExcluded: metadataChanged
                      ? optionalBoolValue(s.metadata.cropExcluded)
                      : const Value.absent(),
                  searchText: metadataChanged
                      ? Value(
                          ScoresRepository.generateSearchText([
                            s.title,
                            s.metadata.composer ?? score.composer,
                            s.metadata.arranger ?? score.arranger,
                            s.metadata.partOf ?? score.partOf,
                          ]),
                        )
                      : const Value.absent(),
                  fileUpdatedAt: fileChanged
                      ? Value(s.fileUpdatedAt.toUtc())
                      : const Value.absent(),
                  fileUploaded: fileChanged
                      ? const Value(false)
                      : const Value.absent(),
                  fileDownloaded: fileChanged
                      ? const Value(true)
                      : const Value.absent(),
                  fileType: fileChanged
                      ? Value(s.fileType)
                      : const Value.absent(),
                  type: metadataChanged && s.type != null
                      ? Value(s.type!)
                      : const Value.absent(),
                ),
              );
          if (fileChanged) await _db.clearProcessingResult(s.id);
        }
        if (metadataChanged) {
          await _db.managers.scoreTagsTable
              .filter((f) => f.score.id(s.id))
              .delete();
          if (s.metadata.instruments != null) {
            await _db.managers.instrumentsTable
                .filter((f) => f.score.id(s.id))
                .delete();
          }
          if (s.metadata.genres != null) {
            await _db.managers.genresTable
                .filter((f) => f.score.id(s.id))
                .delete();
          }
        }
        if (score == null || metadataChanged) {
          if (s.tagIds.isNotEmpty) {
            final tagIds = await _knownTagIds("score ${s.id}", s.tagIds);
            if (tagIds.isNotEmpty) {
              await _db.managers.scoreTagsTable.bulkCreate(
                (o) => tagIds.map((t) => o(score: s.id, tag: t)),
              );
            }
          }
          if ((s.metadata.instruments ?? []).isNotEmpty) {
            await _db.managers.instrumentsTable.bulkCreate(
              (o) => s.metadata.instruments!.map(
                (i) => o(score: s.id, instrument: i),
              ),
            );
          }
          if ((s.metadata.genres ?? []).isNotEmpty) {
            await _db.managers.genresTable.bulkCreate(
              (o) => s.metadata.genres!.map((g) => o(score: s.id, genre: g)),
            );
          }
          _changedScores.add(s.id);
        }
      });

      if (deleteFile != null) {
        try {
          await deleteFile!.delete();
        } catch (_) {}
      }
    }
  }

  /// file_selector on Android copies the picked file to {cacheDir}/{uuid}/.
  Future<void> _deletePickerCopy(XFile file, Directory tempDir) async {
    final copyDir = path.dirname(file.path);
    if (!path.equals(path.dirname(copyDir), tempDir.path) ||
        !_uuid.hasMatch(path.basename(copyDir))) {
      return;
    }
    try {
      await File(file.path).delete();
      await Directory(copyDir).delete();
    } catch (e) {
      Log.warn("Failed to delete picked import file: $e");
    }
  }

  static final _uuid = RegExp(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
  );

  static Future<void> _saveJson(Map params) async {
    final json = jsonEncode(params["models"]);
    await File(
      path.join(params["dir"], params["fileName"]),
    ).writeAsString(json, encoding: utf8, flush: true, mode: FileMode.write);
  }

  static Future<void> _createZipFile(Map params) async {
    final encoder = ZipFileEncoder()
      ..create(params["path"], level: DeflateLevel.defaultCompression);
    try {
      await encoder.addDirectory(
        Directory(params["dir"]),
        includeDirName: false,
      );
      encoder.addArchiveFile(ArchiveFile.directory("scores/"));
      final files = params["files"] as Map<String, String>;
      for (final MapEntry(key: name, value: filePath) in files.entries) {
        try {
          await encoder.addFile(File(filePath), name);
        } on PathNotFoundException {
          // the file was replaced after the export read the rows
        }
      }
      encoder.addArchiveFile(ArchiveFile.bytes(".sheetopia", const []));
    } finally {
      await encoder.close();
    }
  }

  static _ArchiveData _readArchive(Archive archive) {
    if (archive.findFile(".sheetopia") == null) {
      throw InvalidFileException("missing .sheetopia marker file");
    }

    List<T> readList<T>(
      String name,
      T Function(Map<String, dynamic> json) fromJson, {
      bool required = false,
    }) {
      final file = archive.findFile(name);
      if (file == null) {
        if (required) throw InvalidFileException("missing $name");
        return const [];
      }
      final json =
          jsonDecode(utf8.decode(file.readBytes() ?? const []))
              as List<dynamic>;
      return json.map((e) => fromJson(e)).toList();
    }

    try {
      final scores = readList(
        "scores.json",
        ScoreModel.fromJson,
        required: true,
      );
      for (final s in scores) {
        if (!isSafeId(s.id)) {
          throw InvalidFileException("invalid score id: ${s.id}");
        }
      }
      return (
        tags: readList("tags.json", TagModel.fromJson, required: true),
        scores: scores,
        setlists: readList("setlists.json", SetlistModel.fromJson),
        categories: readList(
          "exercise_categories.json",
          ExerciseCategoryModel.fromJson,
        ),
        exercises: readList("exercises.json", ExerciseModel.fromJson),
        routines: readList(
          "practice_routines.json",
          PracticeRoutineModel.fromJson,
        ),
        records: readList(
          "practice_records.json",
          PracticeRecordModel.fromJson,
        ),
        fileNames: {
          for (final f in archive)
            if (f.isFile) f.name,
        },
      );
    } on InvalidFileException {
      rethrow;
    } on Exception catch (e) {
      throw InvalidFileException(e.toString());
    } on TypeError catch (e) {
      throw InvalidFileException(e.toString());
    }
  }

  Value<String?> _annotationsColumnValue(Map<String, dynamic>? a) {
    if (a == null) return const Value.absent();
    if (a.isEmpty) return const Value(null);
    return Value(jsonEncode(a));
  }
}
