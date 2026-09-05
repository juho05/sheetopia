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
import 'package:io/io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/exercise_categories.dart';
import 'package:sheetopia/data/services/sync/models/exercise_metadata.dart';
import 'package:sheetopia/data/services/sync/models/exercises.dart';
import 'package:sheetopia/data/services/sync/models/practice_routines.dart';
import 'package:sheetopia/data/services/sync/models/practice_sessions.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

enum ImportExportStatus { idle, importing, exporting }

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
      final extension = path.extension(zipFile.path);
      if (extension != ".zip") {
        throw InvalidFileException("invalid file extension: $extension");
      }

      onSelected?.call();

      final tempDir = await getTemporaryDirectory();
      final dir = await tempDir.createTemp("sheetopia-import-");
      try {
        final result = await compute(_decodeZIPFile, {
          "inputPath": zipFile.path,
          "outputPath": dir.path,
        });

        final tags = result["tags"] as List<TagModel>;
        final scores = result["scores"] as List<ScoreModel>;
        final setlists = result["setlists"] as List<SetlistModel>;
        final categories = result["categories"] as List<ExerciseCategoryModel>;
        final exercises = result["exercises"] as List<ExerciseModel>;
        final routines = result["routines"] as List<PracticeRoutineModel>;
        final sessions = result["sessions"] as List<PracticeSessionModel>;
        final scoresDir = result["scoresDir"] as String;

        final importedAt = DateTime.now().toUtc();

        await _importTags(tags, importedAt);
        await _importScores(scores, scoresDir, importedAt);
        await _importSetlists(setlists, importedAt);
        await _importExerciseCategories(categories, importedAt);
        await _importExercises(exercises, importedAt);
        await _importPracticeRoutines(routines, importedAt);
        await _importPracticeSessions(sessions, importedAt);
      } finally {
        await dir.delete(recursive: true);
      }
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _setlistsRepo.remoteChangedSetlists(_changedSetlists);
      _practiceRepo.remoteChangedCategories(_changedCategories);
      _practiceRepo.remoteChangedExercises(_changedExercises);
      _practiceRepo.remoteChangedRoutines(_changedRoutines);
      _changedScores = {};
      _changedTags = {};
      _changedSetlists = {};
      _changedCategories = {};
      _changedExercises = {};
      _changedRoutines = {};
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
      final dir = await tempDir.createTemp("sheetopia-export-");
      final scoresTargetDir = Directory(path.join(dir.path, "scores"));
      await scoresTargetDir.create();

      try {
        final scoresDir = await _scoresRepo.scoresDir;

        await copyPath(scoresDir.path, scoresTargetDir.path);

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
            "dir": dir.path,
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
            scoreModels.addAll(
              scores
                  .where((s) => s.file != null)
                  .map(
                    (s) => ScoreModel(
                      id: s.id,
                      title: s.title,
                      fileType: s.fileType,
                      fileUpdatedAt: s.fileUpdatedAt,
                      metadata: ScoreMetadataModel(
                        composer: s.composer,
                        source: s.source,
                        sourceLink: s.sourceLink,
                        genres: s.genres,
                        instruments: s.instruments,
                        notes: s.notes,
                        annotations: s.annotations == null
                            ? {}
                            : jsonDecode(s.annotations!)
                                  as Map<String, dynamic>,
                      ),
                      metadataUpdatedAt: s.metadataUpdatedAt,
                      tagIds: s.tags.map((t) => t.id).toList(),
                      type: s.type,
                    ),
                  ),
            );
            if (scores.length < 500) break;
            offset += scores.length;
          }

          await compute(_saveJson, {
            "dir": dir.path,
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
            "dir": dir.path,
            "fileName": "setlists.json",
            "models": setlistModels,
          });
        }

        {
          final categories = await _db.managers.exerciseCategoriesTable.get();
          await compute(_saveJson, {
            "dir": dir.path,
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
            "dir": dir.path,
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
                    targetBpm: e.targetBpm ?? 0,
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
            "dir": dir.path,
            "fileName": "practice_routines.json",
            "models": [
              for (final r in routines)
                PracticeRoutineModel(
                  id: r.id,
                  name: r.name,
                  metadata: PracticeRoutineMetadataModel(
                    description: r.description ?? "",
                  ),
                  entries: entries[r.id] ?? [],
                  updatedAt: r.updatedAt.toUtc(),
                ),
            ],
          });
        }

        {
          final sessions = await _db.managers.practiceSessionsTable.get();

          final entries = <String, List<PracticeSessionEntryModel>>{};
          final sessionEntries = await (_db.select(
            _db.practiceSessionEntriesTable,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
          for (final e in sessionEntries) {
            entries
                .putIfAbsent(e.session, () => [])
                .add(
                  PracticeSessionEntryModel(
                    id: e.id,
                    exerciseId: e.exercise,
                    routineEntryId: e.routineEntry,
                    metadata: PracticeSessionEntryMetadataModel(
                      duration: e.duration.inMilliseconds,
                    ),
                  ),
                );
          }

          await compute(_saveJson, {
            "dir": dir.path,
            "fileName": "practice_sessions.json",
            "models": [
              for (final s in sessions)
                PracticeSessionModel(
                  id: s.id,
                  startedAt: s.startedAt.toUtc(),
                  endedAt: s.endedAt?.toUtc(),
                  routineId: s.routine,
                  metadata: PracticeSessionMetadataModel(
                    description: s.description ?? "",
                  ),
                  entries: entries[s.id] ?? [],
                  updatedAt: s.updatedAt.toUtc(),
                ),
            ],
          });
        }

        // create marker file
        await File(path.join(dir.path, ".sheetopia")).create();

        final zipFileDir = await tempDir.createTemp();

        try {
          final datetime = DateTime.now();

          final fileName =
              "sheetopia-export-${DateFormat("yyyy-MM-dd_HH-mm-ss").format(datetime)}.zip";

          final zipFile = File(path.join(zipFileDir.path, fileName));

          await compute(_createZipFileFromDir, {
            "dir": dir.path,
            "path": zipFile.path,
          });

          await dir.delete(recursive: true);

          if (Platform.isIOS || Platform.isAndroid) {
            // TODO provide an option for android users to save file locally
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
          }

          final result = await getSaveLocation(
            suggestedName: path.basename(zipFile.path),
            acceptedTypeGroups: [zipTypeGroup],
            canCreateDirectories: true,
          );

          if (result == null) {
            return false;
          }

          await zipFile.copy(result.path);
        } finally {
          await zipFileDir.delete(recursive: true);
        }
      } finally {
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      }
      return true;
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
            description: _optionalStringValue(e.metadata.description),
            source: _optionalStringValue(e.metadata.source),
            sourceLink: _optionalStringValue(e.metadata.sourceLink),
            instrument: _optionalStringValue(e.metadata.instrument),
            targetBpm: _optionalIntValue(e.metadata.targetBpm),
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
              targetBpm: e.metadata.targetBpm != null
                  ? excluded.targetBpm
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
                description: _optionalStringValue(r.metadata.description),
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
                extraNotes: _optionalStringValue(e.$2.metadata.extraNotes),
                defaultScore: _optionalStringValue(
                  e.$2.metadata.defaultScoreId,
                ),
                targetDuration: _optionalDurationValue(
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

  Future<void> _importPracticeSessions(
    List<PracticeSessionModel> sessions,
    DateTime importedAt,
  ) async {
    await _dropPendingTombstones(
      sessions.map((s) => s.id).toList(),
      (chunk) => _db.managers.deletedPracticeSessionsTable
          .filter((f) => f.sessionId.isIn(chunk))
          .delete(),
    );

    for (final s in sessions) {
      await _db.transaction(() async {
        final result = await _db.managers.practiceSessionsTable
            .createReturningOrNull(
              (o) => o(
                id: s.id,
                startedAt: s.startedAt.toUtc(),
                endedAt: Value(s.endedAt?.toUtc()),
                routine: Value(s.routineId),
                description: _optionalStringValue(s.metadata.description),
                updatedAt: Value(s.updatedAt.toUtc()),
                writtenAt: Value(importedAt),
                uploaded: const Value(false),
              ),
              onConflict: DoUpdate.withExcluded(
                (old, excluded) => PracticeSessionsTableCompanion.custom(
                  startedAt: excluded.startedAt,
                  endedAt: excluded.endedAt,
                  routine: excluded.routine,
                  description: s.metadata.description != null
                      ? excluded.description
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

        await _db.managers.practiceSessionEntriesTable
            .filter((f) => f.session.id(s.id))
            .delete();
        if (s.entries.isNotEmpty) {
          await _db.managers.practiceSessionEntriesTable.bulkCreate(
            (o) => s.entries.map(
              (e) => o(
                id: e.id,
                session: s.id,
                exercise: e.exerciseId,
                routineEntry: Value(e.routineEntryId),
                duration: Value(
                  Duration(milliseconds: e.metadata.duration ?? 0),
                ),
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _importScores(
    List<ScoreModel> scores,
    String scoresDir,
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
        final fileChanged =
            score != null && score.fileUpdatedAt.isBefore(s.fileUpdatedAt);

        if (score == null || fileChanged) {
          final scoreFile = File(
            path.join(
              scoresDir,
              s.id,
              "score${fileTypeToExtension(s.fileType)}",
            ),
          );
          if (!await scoreFile.exists()) {
            throw InvalidFileException("missing score file for ${s.id}");
          }

          await _scoresRepo.createScoreDir(s.id);
          final targetScoreFile = await _scoresRepo.scoreFile(s.id, s.fileType);
          await scoreFile.copy(targetScoreFile.path);
          await _thumbnailService.invalidateThumbnails({s.id});

          if (score != null && score.fileType != s.fileType) {
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
              ]),
              title: s.title,
              composer: _optionalStringValue(s.metadata.composer),
              source: _optionalStringValue(s.metadata.source),
              sourceLink: _optionalStringValue(s.metadata.sourceLink),
              notes: _optionalStringValue(s.metadata.notes),
              annotations: _annotationsColumnValue(s.metadata.annotations),
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
                      ? _optionalStringValue(s.metadata.composer)
                      : const Value.absent(),
                  source: metadataChanged
                      ? _optionalStringValue(s.metadata.source)
                      : const Value.absent(),
                  sourceLink: metadataChanged
                      ? _optionalStringValue(s.metadata.sourceLink)
                      : const Value.absent(),
                  notes: metadataChanged
                      ? _optionalStringValue(s.metadata.notes)
                      : const Value.absent(),
                  annotations: metadataChanged
                      ? _annotationsColumnValue(s.metadata.annotations)
                      : const Value.absent(),
                  searchText: metadataChanged
                      ? Value(
                          ScoresRepository.generateSearchText([
                            s.title,
                            s.metadata.composer,
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

  static Future<void> _saveJson(Map params) async {
    final json = jsonEncode(params["models"]);
    await File(
      path.join(params["dir"], params["fileName"]),
    ).writeAsString(json, encoding: utf8, flush: true, mode: FileMode.write);
  }

  static Future<List<T>> _readOptionalJsonList<T>(
    String dir,
    String fileName,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final file = File(path.join(dir, fileName));
    if (!await file.exists()) return const [];
    final json =
        jsonDecode(await file.readAsString(encoding: utf8)) as List<dynamic>;
    return json.map((e) => fromJson(e)).toList();
  }

  static Future<void> _createZipFileFromDir(Map params) async {
    final archive = createArchiveFromDirectory(
      Directory(params["dir"]),
      includeDirName: false,
    );

    final outStream = OutputFileStream(params["path"]);

    try {
      ZipEncoder().encodeStream(
        archive,
        outStream,
        autoClose: true,
        level: DeflateLevel.defaultCompression,
      );
    } finally {
      outStream.close();
    }
  }

  static Future<Map> _decodeZIPFile(Map params) async {
    final inputPath = params["inputPath"];
    final outputPath = params["outputPath"];

    await extractFileToDisk(inputPath, outputPath);

    if (!await File(path.join(outputPath, ".sheetopia")).exists()) {
      throw InvalidFileException("missing .sheetopia marker file");
    }

    try {
      List<TagModel> tags;
      {
        final tagsJson =
            jsonDecode(
                  await File(
                    path.join(outputPath, "tags.json"),
                  ).readAsString(encoding: utf8),
                )
                as List<dynamic>;
        tags = tagsJson.map((tag) => TagModel.fromJson(tag)).toList();
      }

      List<ScoreModel> scores;
      {
        final scoresJson =
            jsonDecode(
                  await File(
                    path.join(outputPath, "scores.json"),
                  ).readAsString(encoding: utf8),
                )
                as List<dynamic>;
        scores = scoresJson.map((score) => ScoreModel.fromJson(score)).toList();
      }

      final setlists = await _readOptionalJsonList(
        outputPath,
        "setlists.json",
        SetlistModel.fromJson,
      );

      final categories = await _readOptionalJsonList(
        outputPath,
        "exercise_categories.json",
        ExerciseCategoryModel.fromJson,
      );

      final exercises = await _readOptionalJsonList(
        outputPath,
        "exercises.json",
        ExerciseModel.fromJson,
      );

      final routines = await _readOptionalJsonList(
        outputPath,
        "practice_routines.json",
        PracticeRoutineModel.fromJson,
      );

      final sessions = await _readOptionalJsonList(
        outputPath,
        "practice_sessions.json",
        PracticeSessionModel.fromJson,
      );

      final scoresDir = Directory(path.join(outputPath, "scores"));
      if (!await scoresDir.exists()) {
        throw InvalidFileException("missing scores directory");
      }

      return {
        "scores": scores,
        "tags": tags,
        "setlists": setlists,
        "categories": categories,
        "exercises": exercises,
        "routines": routines,
        "sessions": sessions,
        "scoresDir": scoresDir.path,
      };
    } on Exception catch (e) {
      throw InvalidFileException(e.toString());
    }
  }

  Value<String?> _optionalStringValue(String? str) {
    if (str == null) return const Value.absent();
    if (str == "") return const Value(null);
    return Value(str);
  }

  Value<int?> _optionalIntValue(int? value) {
    if (value == null) return const Value.absent();
    if (value == 0) return const Value(null);
    return Value(value);
  }

  Value<Duration?> _optionalDurationValue(int? milliseconds) {
    if (milliseconds == null) return const Value.absent();
    if (milliseconds == 0) return const Value(null);
    return Value(Duration(milliseconds: milliseconds));
  }

  Value<String?> _annotationsColumnValue(Map<String, dynamic>? a) {
    if (a == null) return const Value.absent();
    if (a.isEmpty) return const Value(null);
    return Value(jsonEncode(a));
  }
}
