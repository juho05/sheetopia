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

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage_linux.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage_secure_storage.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';
import 'package:sheetopia/data/services/sync/models/exercise_metadata.dart';
import 'package:sheetopia/data/services/sync/models/practice_routines.dart';
import 'package:sheetopia/data/services/sync/models/practice_sessions.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

enum SyncState { none, failure, partial, syncing, success }

class SyncRepository {
  static const _defaultSyncDelay = Duration(seconds: 30);

  static const minAPIVersionSetlist = Version(major: 0, minor: 2);

  static const minAPIVersionResurrect = Version(major: 0, minor: 3);

  static const minAPIVersionDeletedAt = Version(major: 0, minor: 3);

  static const minAPIVersionType = Version(major: 0, minor: 4);

  static const minAPIVersionPractice = Version(major: 0, minor: 4);

  final ScoresRepository _scoresRepo;
  final SetlistsRepository _setlistsRepo;
  final PracticeRepository _practiceRepo;
  final KeyValueRepository _keyValue;
  final Database _db;
  final SyncService _service;
  final ThumbnailService _thumbnailService;

  final EncryptedStorage _encryptedStorage;

  final ValueNotifier<SyncState> state = ValueNotifier(SyncState.none);

  static const String _lastSyncKey = "last_sync";

  final ValueNotifier<DateTime?> lastSync = ValueNotifier(null);

  Set<String> _changedScores = {};
  Set<String> _changedTags = {};
  Set<String> _changedSetlists = {};
  Set<String> _changedCategories = {};
  Set<String> _changedExercises = {};
  Set<String> _changedRoutines = {};

  bool _itemsFailed = false;

  static const String _userKey = "auth.user";
  static const String _conKey = "sheetopia/auth.con";

  SyncConnection? _con;
  String? _user;

  bool get signedIn => _con != null;

  String get user => _user ?? "unknown";

  Uri get serverUri => _con!.baseUri;

  AppLifecycleListener? _listener;

  SyncRepository({
    required this._scoresRepo,
    required this._setlistsRepo,
    required this._practiceRepo,
    required KeyValueRepository keyValue,
    required this._db,
    required SyncService syncService,
    required this._thumbnailService,
    @visibleForTesting EncryptedStorage? encryptedStorage,
  }) : _keyValue = keyValue,
       _service = syncService,
       _encryptedStorage =
           encryptedStorage ??
           (Platform.isLinux
               ? EncryptedStorageLinux(keyValueRepo: keyValue)
               : EncryptedStorageSecureStorage()) {
    _load().then((value) {
      _scoresRepo.locallyUpdatedScoreIds.listen((event) => requestSync());
      _scoresRepo.locallyUpdatedTagIds.listen((event) => requestSync());
      _setlistsRepo.locallyUpdatedSetlistIds.listen((event) => requestSync());
      _practiceRepo.locallyUpdatedCategoryIds.listen((event) => requestSync());
      _practiceRepo.locallyUpdatedExerciseIds.listen((event) => requestSync());
      _practiceRepo.locallyUpdatedRoutineIds.listen((event) => requestSync());
      _listener = AppLifecycleListener(
        onDetach: _disableSyncing,
        onPause: _disableSyncing,
        onResume: _enableSyncing,
      );
    });
  }

  bool _syncingEnabled = true;

  void _disableSyncing() {
    if (!_syncingEnabled) return;
    _syncingEnabled = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    if (state.value != SyncState.syncing &&
        _nextSyncDelay < _defaultSyncDelay) {
      _sync();
    } else {
      state.value = SyncState.none;
      _nextSyncDelay = _defaultSyncDelay;
    }
  }

  void _enableSyncing() {
    if (_syncingEnabled) return;
    _syncingEnabled = true;
    _sync();
  }

  Future<bool> isSheetopiaUri(Uri baseUri) async {
    try {
      final info = await _service.getServerInfo(baseUri);
      if (info.server != "sheetopia-sync") return false;
      return true;
    } on InvalidResponseBody catch (_) {
      return false;
    } on StatusCodeException catch (_) {
      return false;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse ||
          (e.type == DioExceptionType.unknown &&
              e.error != null &&
              e.error!.toString().contains("is not a subtype of"))) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> login({
    required Uri baseUri,
    required String user,
    required String password,
  }) async {
    if (signedIn) throw Exception("already signed in");
    _con = await _service.login(baseUri, user: user, password: password);
    _user = user;

    await _encryptedStorage.write(_conKey, jsonEncode(_con!));
    await _keyValue.store(_userKey, user);

    await _db.managers.deletedScoresTable.delete();
    await _db.managers.deletedTagsTable.delete();
    await _db.managers.deletedSetlistsTable.delete();
    await _db.managers.deletedExerciseCategoriesTable.delete();
    await _db.managers.deletedExercisesTable.delete();
    await _db.managers.deletedPracticeRoutinesTable.delete();
    await _db.managers.deletedPracticeSessionsTable.delete();

    _sync();
  }

  Future<void> logout() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _nextSyncDelay = _defaultSyncDelay;
    _con = null;
    _user = null;
    state.value = SyncState.none;

    await _updateLastSync(null);
    await _keyValue.remove(_userKey);
    await _encryptedStorage.delete(_conKey);

    await _db.managers.scoresTable.update(
      (o) => o(
        metadataUploaded: const Value(false),
        fileUploaded: const Value(false),
      ),
    );
    await _db.managers.tagsTable.update((o) => o(uploaded: const Value(false)));
    await _db.managers.setlistsTable.update(
      (o) => o(uploaded: const Value(false)),
    );
    await _db.managers.exerciseCategoriesTable.update(
      (o) => o(uploaded: const Value(false)),
    );
    await _db.managers.exercisesTable.update(
      (o) => o(uploaded: const Value(false)),
    );
    await _db.managers.practiceRoutinesTable.update(
      (o) => o(uploaded: const Value(false)),
    );
    await _db.managers.practiceSessionsTable.update(
      (o) => o(uploaded: const Value(false)),
    );
  }

  Future<void> _load() async {
    final conStr = await _encryptedStorage.read(_conKey);
    if (conStr == null) {
      await _keyValue.remove(_conKey);
      await _scoresRepo.deleteAbandonedScores();
      return;
    }
    _con = SyncConnection.fromJson(jsonDecode(conStr));
    _user = await _keyValue.loadString(_userKey);

    try {
      _user = await _service.getUser(_con!);
    } on UnauthenticatedException catch (_) {
      await logout();
      return;
    } on DioException catch (_) {
      // server unreachable at the moment, use cached user value
    }

    _sync();
  }

  Future<void> syncNow() async {
    if (!signedIn) return;
    _nextSyncDelay = Duration.zero;
    if (state.value != SyncState.syncing) {
      _scheduleSync();
    }
  }

  void requestSync() {
    if (!signedIn) return;
    _nextSyncDelay = const Duration(seconds: 5);
    if (state.value != SyncState.syncing) {
      _scheduleSync();
    }
  }

  Duration _nextSyncDelay = _defaultSyncDelay;
  Timer? _syncTimer;

  void _scheduleSync() {
    if (!signedIn) return;
    _syncTimer?.cancel();
    _syncTimer = null;
    if (!_syncingEnabled) {
      _nextSyncDelay = _defaultSyncDelay;
      state.value = SyncState.none;
      return;
    }
    _syncTimer = Timer(_nextSyncDelay, () {
      _syncTimer = null;
      _nextSyncDelay = _defaultSyncDelay;
      _sync();
    });
  }

  Future<void> _sync() async {
    if (!signedIn) return;
    if (state.value == SyncState.syncing) return;
    state.value = SyncState.syncing;
    _itemsFailed = false;

    try {
      if (lastSync.value == null) {
        await _loadLastSync();
      }

      final serverInfo = await _service.getServerInfo(_con!.baseUri);
      final syncTime = serverInfo.time;
      final apiVersion = Version.parse(serverInfo.apiVersion);
      final sendWrittenAt = apiVersion >= minAPIVersionResurrect;
      final honourDeletedAt = apiVersion >= minAPIVersionDeletedAt;
      final sendType = apiVersion >= minAPIVersionType;

      await _uploadDeletedTags();
      await _uploadDeletedScores();
      if (apiVersion >= minAPIVersionSetlist) {
        await _uploadDeletedSetlists();
      }
      if (apiVersion >= minAPIVersionPractice) {
        await _uploadDeletedPracticeSessions();
        await _uploadDeletedPracticeRoutines();
        await _uploadDeletedExercises();
        await _uploadDeletedExerciseCategories();
      }

      await _downloadDeletedTags(honourDeletedAt);

      await _uploadTagChanges(sendWrittenAt, sendType);
      await _downloadTagChanges();

      await _downloadDeletedScores(honourDeletedAt);

      await _uploadMetadataChanges(sendWrittenAt, sendType);
      await _uploadFileChanges();

      await _downloadMetadataChanges();
      await _downloadFileChanges();

      if (apiVersion >= minAPIVersionSetlist) {
        await _downloadDeletedSetlists(honourDeletedAt);
        await _uploadSetlistChanges(sendWrittenAt);
        await _downloadSetlistChanges();
      }

      if (apiVersion >= minAPIVersionPractice) {
        await _downloadDeletedExerciseCategories(honourDeletedAt);
        await _uploadExerciseCategoryChanges(sendWrittenAt);
        await _downloadExerciseCategoryChanges();

        await _downloadDeletedExercises(honourDeletedAt);
        await _uploadExerciseChanges(sendWrittenAt);
        await _downloadExerciseChanges();

        await _downloadDeletedPracticeRoutines(honourDeletedAt);
        await _uploadPracticeRoutineChanges(sendWrittenAt);
        await _downloadPracticeRoutineChanges();

        await _downloadDeletedPracticeSessions(honourDeletedAt);
        await _uploadPracticeSessionChanges(sendWrittenAt);
        await _downloadPracticeSessionChanges();
      }

      await _updateLastSync(syncTime);

      state.value = _itemsFailed ? SyncState.partial : SyncState.success;
      await _scoresRepo.deleteAbandonedScores();
    } on UnauthenticatedException catch (_) {
      await logout();
    } catch (e, st) {
      if (signedIn) {
        Log.error("Sync failed", e: e, st: st);
        state.value = SyncState.failure;
      }
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _setlistsRepo.remoteChangedSetlists(_changedSetlists);
      _practiceRepo.remoteChangedCategories(_changedCategories);
      _practiceRepo.remoteChangedExercises(_changedExercises);
      _practiceRepo.remoteChangedRoutines(_changedRoutines);
      _changedTags = {};
      _changedScores = {};
      _changedSetlists = {};
      _changedCategories = {};
      _changedExercises = {};
      _changedRoutines = {};
      _scheduleSync();
    }
  }

  Future<void> _uploadDeletedTags() async {
    final startTime = DateTime.now();
    final deletedTagIds = (await _db.managers.deletedTagsTable.get()).map(
      (t) => t.tagId,
    );

    for (final tagId in deletedTagIds) {
      try {
        await _service.deleteTag(_con!, tagId);
      } on NotFoundException catch (_) {
        // tag is already deleted on server or was never synced
      }
    }

    await _db.managers.deletedTagsTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _uploadDeletedScores() async {
    final startTime = DateTime.now();
    final deletedScoreIds = (await _db.managers.deletedScoresTable.get()).map(
      (t) => t.scoreId,
    );

    for (final scoreId in deletedScoreIds) {
      try {
        await _service.deleteScore(_con!, scoreId);
      } on NotFoundException catch (_) {
        // score is already deleted on server or was never synced
      }
    }

    await _db.managers.deletedScoresTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _uploadDeletedSetlists() async {
    final startTime = DateTime.now();
    final deletedSetlistIds = (await _db.managers.deletedSetlistsTable.get())
        .map((s) => s.setlistId);

    for (final setlistId in deletedSetlistIds) {
      try {
        await _service.deleteSetlist(_con!, setlistId);
      } on NotFoundException catch (_) {
        // already deleted on the server or never synced
      }
    }

    await _db.managers.deletedSetlistsTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _downloadDeletedSetlists(bool honourDeletedAt) async {
    final deletedSetlists = await _service.getDeletedSetlists(
      _con!,
      since: lastSync.value,
    );
    for (final d in deletedSetlists) {
      final setlist = await _db.managers.setlistsTable
          .filter((f) => f.id(d.id))
          .getSingleOrNull();
      if (setlist == null) continue;

      if (honourDeletedAt &&
          _shouldKeepAfterRemoteDelete(
            deletedAt: d.deletedAt,
            writtenAt: setlist.writtenAt,
          )) {
        Log.debug(
          "Keeping setlist ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${setlist.writtenAt}",
        );
        await _db.managers.setlistsTable
            .filter((f) => f.id(d.id))
            .update((o) => o(uploaded: const Value(false)));
        continue;
      }

      if (!setlist.uploaded) {
        Log.warn(
          "Discarding unsynced local changes to setlist ${d.id}: deleted on the server",
        );
      }
      await _db.managers.setlistsTable.filter((f) => f.id(d.id)).delete();
      _changedSetlists.add(d.id);
    }
  }

  Future<void> _uploadSetlistChanges(bool sendWrittenAt) async {
    final changedSetlists = await _db.managers.setlistsTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final s in changedSetlists) {
      final entries =
          await (_db.select(_db.setlistEntriesTable)
                ..where((t) => t.setlist.equals(s.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      try {
        await _service.updateSetlist(
          _con!,
          s.id,
          name: s.name,
          scoreIds: entries.map((e) => e.score).toList(),
          updatedAt: s.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? s.writtenAt?.toUtc() : null,
        );
        await _markSetlistUploaded(s.id, s.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markSetlistUploaded(s.id, s.updatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping upload of setlist ${s.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload setlist ${s.id}", e: e);
      }
    }
  }

  Future<void> _markSetlistUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.setlistsTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadSetlistChanges() async {
    final setlists = await _service.getSetlists(
      _con!,
      changedAfter: lastSync.value,
    );
    for (final s in setlists) {
      await _db.transaction(() async {
        final result = await _db.managers.setlistsTable.createReturningOrNull(
          (o) => o(
            id: s.id,
            name: s.name,
            updatedAt: Value(s.updatedAt.toUtc()),
            uploaded: const Value(true),
          ),
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => SetlistsTableCompanion.custom(
              name: excluded.name,
              uploaded: excluded.uploaded,
              updatedAt: excluded.updatedAt,
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

  Future<void> _uploadDeletedExerciseCategories() async {
    final startTime = DateTime.now();
    final ids = (await _db.managers.deletedExerciseCategoriesTable.get()).map(
      (c) => c.categoryId,
    );

    for (final id in ids) {
      try {
        await _service.deleteExerciseCategory(_con!, id);
      } on NotFoundException catch (_) {
        // already deleted on the server or never synced
      }
    }

    await _db.managers.deletedExerciseCategoriesTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _uploadDeletedExercises() async {
    final startTime = DateTime.now();
    final ids = (await _db.managers.deletedExercisesTable.get()).map(
      (e) => e.exerciseId,
    );

    for (final id in ids) {
      try {
        await _service.deleteExercise(_con!, id);
      } on NotFoundException catch (_) {
        // already deleted on the server or never synced
      }
    }

    await _db.managers.deletedExercisesTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _uploadDeletedPracticeRoutines() async {
    final startTime = DateTime.now();
    final ids = (await _db.managers.deletedPracticeRoutinesTable.get()).map(
      (r) => r.routineId,
    );

    for (final id in ids) {
      try {
        await _service.deletePracticeRoutine(_con!, id);
      } on NotFoundException catch (_) {
        // already deleted on the server or never synced
      }
    }

    await _db.managers.deletedPracticeRoutinesTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _uploadDeletedPracticeSessions() async {
    final startTime = DateTime.now();
    final ids = (await _db.managers.deletedPracticeSessionsTable.get()).map(
      (s) => s.sessionId,
    );

    for (final id in ids) {
      try {
        await _service.deletePracticeSession(_con!, id);
      } on NotFoundException catch (_) {
        // already deleted on the server or never synced
      }
    }

    await _db.managers.deletedPracticeSessionsTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _downloadDeletedExerciseCategories(bool honourDeletedAt) async {
    final deleted = await _service.getDeletedExerciseCategories(
      _con!,
      since: lastSync.value,
    );
    for (final d in deleted) {
      await _db.transaction(() async {
        final category = await _db.managers.exerciseCategoriesTable
            .filter((f) => f.id(d.id))
            .getSingleOrNull();
        if (category == null) return;

        if (honourDeletedAt &&
            _shouldKeepAfterRemoteDelete(
              deletedAt: d.deletedAt,
              writtenAt: category.writtenAt,
            )) {
          Log.debug(
            "Keeping exercise category ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${category.writtenAt}",
          );
          await _db.managers.exerciseCategoriesTable
              .filter((f) => f.id(d.id))
              .update((o) => o(uploaded: const Value(false)));
          return;
        }

        if (!category.uploaded) {
          Log.warn(
            "Discarding unsynced local changes to exercise category ${d.id}: deleted on the server",
          );
        }

        // the exercises are only unlinked, the device that deleted the category uploads their new state
        final affected = await _db.managers.exercisesTable
            .filter((f) => f.category.id(d.id))
            .map((e) => e.id)
            .get();
        if (affected.isNotEmpty) {
          await _db.managers.exercisesTable
              .filter((f) => f.category.id(d.id))
              .update((o) => o(category: const Value(null)));
          _changedExercises.addAll(affected);
        }

        await _db.managers.exerciseCategoriesTable
            .filter((f) => f.id(d.id))
            .delete();
        _changedCategories.add(d.id);
      });
    }
  }

  Future<void> _uploadExerciseCategoryChanges(bool sendWrittenAt) async {
    final changed = await _db.managers.exerciseCategoriesTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final c in changed) {
      try {
        await _service.updateExerciseCategory(
          _con!,
          c.id,
          name: c.name,
          position: c.position,
          updatedAt: c.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? c.writtenAt?.toUtc() : null,
        );
        await _markExerciseCategoryUploaded(c.id, c.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markExerciseCategoryUploaded(c.id, c.updatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping upload of exercise category ${c.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload exercise category ${c.id}", e: e);
      }
    }
  }

  Future<void> _markExerciseCategoryUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.exerciseCategoriesTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadExerciseCategoryChanges() async {
    final categories = await _service.getExerciseCategories(
      _con!,
      changedAfter: lastSync.value,
    );
    for (final c in categories) {
      final result = await _db.managers.exerciseCategoriesTable
          .createReturningOrNull(
            (o) => o(
              id: c.id,
              name: c.name,
              position: c.position,
              updatedAt: Value(c.updatedAt.toUtc()),
              uploaded: const Value(true),
            ),
            onConflict: DoUpdate.withExcluded(
              (old, excluded) => ExerciseCategoriesTableCompanion.custom(
                name: excluded.name,
                position: excluded.position,
                uploaded: excluded.uploaded,
                updatedAt: excluded.updatedAt,
              ),
              where: (old, excluded) =>
                  old.updatedAt.isSmallerThan(excluded.updatedAt),
            ),
          );
      if (result != null) _changedCategories.add(c.id);
    }
  }

  Future<void> _downloadDeletedExercises(bool honourDeletedAt) async {
    final deleted = await _service.getDeletedExercises(
      _con!,
      since: lastSync.value,
    );
    for (final d in deleted) {
      await _db.transaction(() async {
        final exercise = await _db.managers.exercisesTable
            .filter((f) => f.id(d.id))
            .getSingleOrNull();
        if (exercise == null) return;

        if (honourDeletedAt &&
            _shouldKeepAfterRemoteDelete(
              deletedAt: d.deletedAt,
              writtenAt: exercise.writtenAt,
            )) {
          Log.debug(
            "Keeping exercise ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${exercise.writtenAt}",
          );
          await _db.managers.exercisesTable
              .filter((f) => f.id(d.id))
              .update((o) => o(uploaded: const Value(false)));
          return;
        }

        if (!exercise.uploaded) {
          Log.warn(
            "Discarding unsynced local changes to exercise ${d.id}: deleted on the server",
          );
        }

        // the routine entries block the delete, the device that deleted the exercise uploads the new routines
        final affected = await _db.managers.practiceRoutineEntriesTable
            .filter((f) => f.exercise.id(d.id))
            .map((e) => e.routine)
            .get();
        if (affected.isNotEmpty) {
          await _db.managers.practiceRoutineEntriesTable
              .filter((f) => f.exercise.id(d.id))
              .delete();
          await _practiceRepo.renumberRoutineEntries(affected.toSet());
          _changedRoutines.addAll(affected);
        }

        await _db.managers.exercisesTable.filter((f) => f.id(d.id)).delete();
        _changedExercises.add(d.id);
      });
    }
  }

  Future<void> _uploadExerciseChanges(bool sendWrittenAt) async {
    final changed = await _db.managers.exercisesTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final e in changed) {
      final tagIds = await _db.managers.exerciseTagsTable
          .filter((f) => f.exercise.id(e.id))
          .map((t) => t.tag)
          .get();
      final scores =
          await (_db.select(_db.exerciseScoresTable)
                ..where((t) => t.exercise.equals(e.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      try {
        await _service.updateExercise(
          _con!,
          e.id,
          name: e.name,
          categoryId: e.category,
          tagIds: tagIds.toList(),
          scoreIds: scores.map((s) => s.score).toList(),
          metadata: ExerciseMetadataModel(
            description: e.description ?? "",
            source: e.source ?? "",
            sourceLink: e.sourceLink ?? "",
            instrument: e.instrument ?? "",
            targetBpm: e.targetBpm ?? 0,
          ),
          updatedAt: e.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? e.writtenAt?.toUtc() : null,
        );
        await _markExerciseUploaded(e.id, e.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markExerciseUploaded(e.id, e.updatedAt, sendWrittenAt);
      } on DeletedException catch (err) {
        Log.warn(
          "Skipping upload of exercise ${e.id}: deleted on the server at ${err.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (err) {
        _itemsFailed = true;
        Log.warn("Failed to upload exercise ${e.id}", e: err);
      }
    }
  }

  Future<void> _markExerciseUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.exercisesTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadExerciseChanges() async {
    final exercises = await _service.getExercises(
      _con!,
      changedAfter: lastSync.value,
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
            uploaded: const Value(true),
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

  Future<void> _downloadDeletedPracticeRoutines(bool honourDeletedAt) async {
    final deleted = await _service.getDeletedPracticeRoutines(
      _con!,
      since: lastSync.value,
    );
    for (final d in deleted) {
      final routine = await _db.managers.practiceRoutinesTable
          .filter((f) => f.id(d.id))
          .getSingleOrNull();
      if (routine == null) continue;

      if (honourDeletedAt &&
          _shouldKeepAfterRemoteDelete(
            deletedAt: d.deletedAt,
            writtenAt: routine.writtenAt,
          )) {
        Log.debug(
          "Keeping practice routine ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${routine.writtenAt}",
        );
        await _db.managers.practiceRoutinesTable
            .filter((f) => f.id(d.id))
            .update((o) => o(uploaded: const Value(false)));
        continue;
      }

      if (!routine.uploaded) {
        Log.warn(
          "Discarding unsynced local changes to practice routine ${d.id}: deleted on the server",
        );
      }
      await _db.managers.practiceRoutinesTable
          .filter((f) => f.id(d.id))
          .delete();
      _changedRoutines.add(d.id);
    }
  }

  Future<void> _uploadPracticeRoutineChanges(bool sendWrittenAt) async {
    final changed = await _db.managers.practiceRoutinesTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final r in changed) {
      final entries =
          await (_db.select(_db.practiceRoutineEntriesTable)
                ..where((t) => t.routine.equals(r.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      try {
        await _service.updatePracticeRoutine(
          _con!,
          r.id,
          name: r.name,
          metadata: PracticeRoutineMetadataModel(
            description: r.description ?? "",
          ),
          entries: [
            for (final e in entries)
              PracticeRoutineEntryModel(
                id: e.id,
                exerciseId: e.exercise,
                metadata: PracticeRoutineEntryMetadataModel(
                  extraNotes: e.extraNotes ?? "",
                  defaultScoreId: e.defaultScore ?? "",
                  targetDuration: e.targetDuration?.inMilliseconds ?? 0,
                ),
              ),
          ],
          updatedAt: r.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? r.writtenAt?.toUtc() : null,
        );
        await _markPracticeRoutineUploaded(r.id, r.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markPracticeRoutineUploaded(r.id, r.updatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping upload of practice routine ${r.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload practice routine ${r.id}", e: e);
      }
    }
  }

  Future<void> _markPracticeRoutineUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.practiceRoutinesTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadPracticeRoutineChanges() async {
    final routines = await _service.getPracticeRoutines(
      _con!,
      changedAfter: lastSync.value,
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
                uploaded: const Value(true),
              ),
              onConflict: DoUpdate.withExcluded(
                (old, excluded) => PracticeRoutinesTableCompanion.custom(
                  name: excluded.name,
                  description: r.metadata.description != null
                      ? excluded.description
                      : null,
                  uploaded: excluded.uploaded,
                  updatedAt: excluded.updatedAt,
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

  Future<void> _downloadDeletedPracticeSessions(bool honourDeletedAt) async {
    final deleted = await _service.getDeletedPracticeSessions(
      _con!,
      since: lastSync.value,
    );
    for (final d in deleted) {
      final session = await _db.managers.practiceSessionsTable
          .filter((f) => f.id(d.id))
          .getSingleOrNull();
      if (session == null) continue;

      if (honourDeletedAt &&
          _shouldKeepAfterRemoteDelete(
            deletedAt: d.deletedAt,
            writtenAt: session.writtenAt,
          )) {
        Log.debug(
          "Keeping practice session ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${session.writtenAt}",
        );
        await _db.managers.practiceSessionsTable
            .filter((f) => f.id(d.id))
            .update((o) => o(uploaded: const Value(false)));
        continue;
      }

      if (!session.uploaded) {
        Log.warn(
          "Discarding unsynced local changes to practice session ${d.id}: deleted on the server",
        );
      }
      await _db.managers.practiceSessionsTable
          .filter((f) => f.id(d.id))
          .delete();
    }
  }

  Future<void> _uploadPracticeSessionChanges(bool sendWrittenAt) async {
    final changed = await _db.managers.practiceSessionsTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final s in changed) {
      final entries =
          await (_db.select(_db.practiceSessionEntriesTable)
                ..where((t) => t.session.equals(s.id))
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();

      try {
        await _service.updatePracticeSession(
          _con!,
          s.id,
          startedAt: s.startedAt.toUtc(),
          endedAt: s.endedAt?.toUtc(),
          routineId: s.routine,
          metadata: PracticeSessionMetadataModel(
            description: s.description ?? "",
          ),
          entries: [
            for (final e in entries)
              PracticeSessionEntryModel(
                id: e.id,
                exerciseId: e.exercise,
                routineEntryId: e.routineEntry,
                metadata: PracticeSessionEntryMetadataModel(
                  duration: e.duration.inMilliseconds,
                ),
              ),
          ],
          updatedAt: s.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? s.writtenAt?.toUtc() : null,
        );
        await _markPracticeSessionUploaded(s.id, s.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markPracticeSessionUploaded(s.id, s.updatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping upload of practice session ${s.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload practice session ${s.id}", e: e);
      }
    }
  }

  Future<void> _markPracticeSessionUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.practiceSessionsTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadPracticeSessionChanges() async {
    final sessions = await _service.getPracticeSessions(
      _con!,
      changedAfter: lastSync.value,
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
                uploaded: const Value(true),
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

  Future<void> _downloadDeletedTags(bool honourDeletedAt) async {
    final deletedTags = await _service.getDeletedTags(
      _con!,
      since: lastSync.value,
    );
    for (final d in deletedTags) {
      await _db.transaction(() async {
        final tag = await _db.managers.tagsTable
            .filter((f) => f.id(d.id))
            .getSingleOrNull();
        if (tag == null) return;

        if (honourDeletedAt &&
            _shouldKeepAfterRemoteDelete(
              deletedAt: d.deletedAt,
              writtenAt: tag.writtenAt,
            )) {
          Log.debug(
            "Keeping tag ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${tag.writtenAt}",
          );
          await _db.managers.tagsTable
              .filter((f) => f.id(d.id))
              .update((o) => o(uploaded: const Value(false)));
          return;
        }

        if (!tag.uploaded) {
          Log.warn(
            "Discarding unsynced local changes to tag ${d.id}: deleted on the server",
          );
        }

        final affectedScores = await _db.managers.scoreTagsTable
            .filter((f) => f.tag.id(d.id))
            .get();
        _changedScores.addAll(affectedScores.map((s) => s.score));

        final affectedExercises = await _db.managers.exerciseTagsTable
            .filter((f) => f.tag.id(d.id))
            .get();
        _changedExercises.addAll(affectedExercises.map((e) => e.exercise));

        await _db.managers.scoreTagsTable
            .filter((f) => f.tag.id(d.id))
            .delete();
        await _db.managers.exerciseTagsTable
            .filter((f) => f.tag.id(d.id))
            .delete();
        await _db.managers.tagsTable.filter((f) => f.id(d.id)).delete();
        _changedTags.add(d.id);
      });
    }
  }

  Future<void> _uploadTagChanges(bool sendWrittenAt, bool sendType) async {
    final changedTags = await _db.managers.tagsTable
        .filter((f) => f.uploaded.isFalse())
        .get();

    for (final t in changedTags) {
      try {
        await _service.updateTag(
          _con!,
          t.id,
          name: t.name,
          color: t.color,
          updatedAt: t.updatedAt.toUtc(),
          writtenAt: sendWrittenAt ? t.writtenAt?.toUtc() : null,
          type: sendType ? t.type : null,
        );
        await _markTagUploaded(t.id, t.updatedAt, sendWrittenAt);
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markTagUploaded(t.id, t.updatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping upload of tag ${t.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload tag ${t.id}", e: e);
      }
    }
  }

  Future<void> _markTagUploaded(
    String id,
    DateTime updatedAt,
    bool clearWrittenAt,
  ) async {
    await _db.managers.tagsTable
        .filter((f) => f.id(id) & f.updatedAt.equals(updatedAt))
        .update(
          (o) => o(
            uploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _downloadTagChanges() async {
    final tags = await _service.getTags(_con!, changedAfter: lastSync.value);
    for (final t in tags) {
      final result = await _db.managers.tagsTable.createReturningOrNull(
        (o) => o(
          id: t.id,
          name: t.name,
          color: t.color,
          type: t.type != null ? Value(t.type!) : const Value.absent(),
          updatedAt: Value(t.updatedAt.toUtc()),
          uploaded: const Value(true),
        ),
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => TagsTableCompanion.custom(
            name: excluded.name,
            color: excluded.color,
            uploaded: excluded.uploaded,
            updatedAt: excluded.updatedAt,
            type: t.type != null ? excluded.type : null,
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

  Future<void> _downloadDeletedScores(bool honourDeletedAt) async {
    final deletedScores = await _service.getDeletedScores(
      _con!,
      since: lastSync.value,
    );
    final actuallyDeleted = <String>{};
    for (final d in deletedScores) {
      final score = await _db.managers.scoresTable
          .filter((f) => f.id(d.id))
          .getSingleOrNull();

      if (score != null) {
        if (honourDeletedAt &&
            _shouldKeepAfterRemoteDelete(
              deletedAt: d.deletedAt,
              writtenAt: score.writtenAt,
            )) {
          Log.debug(
            "Keeping score ${d.id} deleted on the server at ${d.deletedAt}: restored by an import at ${score.writtenAt}",
          );
          // a file-only re-import leaves the metadata marked as uploaded, so force the resurrect POST
          await _db.managers.scoresTable
              .filter((f) => f.id(d.id))
              .update((o) => o(metadataUploaded: const Value(false)));
          continue;
        }

        if (!score.metadataUploaded ||
            (score.fileDownloaded && !score.fileUploaded)) {
          Log.warn(
            "Discarding unsynced local changes to score ${d.id}: deleted on the server",
          );
        }
      }

      final count = await _db.managers.scoresTable
          .filter((f) => f.id(d.id))
          .delete();
      await _scoresRepo.cleanupScoreFilesAfterDelete(d.id);
      if (count > 0) {
        _changedScores.add(d.id);
        actuallyDeleted.add(d.id);
      }
    }
    _scoresRepo.announceDeletedScores(actuallyDeleted);
  }

  Future<void> _uploadMetadataChanges(bool sendWrittenAt, bool sendType) async {
    final changedScores = await _db.managers.scoresTable
        .withReferences(
          (prefetch) => prefetch(
            scoreTagsTableRefs: true,
            genresTableRefs: true,
            instrumentsTableRefs: true,
          ),
        )
        .filter((f) => f.metadataUploaded.isFalse())
        .get(distinct: true);

    for (final (s, refs) in changedScores) {
      try {
        final result = await _service.updateScore(
          _con!,
          s.id,
          title: s.title,
          metadataUpdatedAt: s.metadataUpdatedAt.toUtc(),
          writtenAt: sendWrittenAt ? s.writtenAt?.toUtc() : null,
          type: sendType ? s.type : null,
          tagIds: (refs.scoreTagsTableRefs.prefetchedData ?? [])
              .map((t) => t.tag)
              .toList(),
          metadata: ScoreMetadataModel(
            composer: s.composer ?? "",
            source: s.source ?? "",
            sourceLink: s.sourceLink ?? "",
            notes: s.notes ?? "",
            genres: (refs.genresTableRefs.prefetchedData ?? [])
                .map((g) => g.genre)
                .toList(),
            instruments: (refs.instrumentsTableRefs.prefetchedData ?? [])
                .map((i) => i.instrument)
                .toList(),
            annotations: s.annotations == null
                ? {}
                : jsonDecode(s.annotations!) as Map<String, dynamic>,
          ),
        );
        await _markMetadataUploaded(
          s.id,
          s.metadataUpdatedAt,
          sendWrittenAt,
          resetFileUploaded: result != null && !result.hasFile,
        );
      } on ConflictException catch (_) {
        // the server holds equal or newer content, the local write is settled
        await _markMetadataUploaded(s.id, s.metadataUpdatedAt, sendWrittenAt);
      } on DeletedException catch (e) {
        Log.warn(
          "Skipping metadata upload of score ${s.id}: deleted on the server at ${e.deletedAt}",
        );
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload metadata of score ${s.id}", e: e);
      }
    }
  }

  Future<void> _markMetadataUploaded(
    String id,
    DateTime metadataUpdatedAt,
    bool clearWrittenAt, {
    bool resetFileUploaded = false,
  }) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(id) & f.metadataUpdatedAt.equals(metadataUpdatedAt))
        .update(
          (o) => o(
            metadataUploaded: const Value(true),
            writtenAt: clearWrittenAt
                ? const Value(null)
                : const Value.absent(),
            fileUploaded: resetFileUploaded
                ? const Value(false)
                : const Value.absent(),
          ),
        );
  }

  Future<void> _uploadFileChanges() async {
    final scores = await _db.managers.scoresTable
        .filter((f) => f.fileDownloaded.isTrue() & f.fileUploaded.isFalse())
        .get();
    for (final s in scores) {
      final file = await _scoresRepo.scoreFile(s.id, s.fileType);
      try {
        await _service.uploadScoreFile(
          _con!,
          s.id,
          file: file,
          updatedAt: s.fileUpdatedAt.toUtc(),
          fileType: s.fileType,
        );
        await _markFileUploaded(s.id, s.fileUpdatedAt);
      } on ConflictException catch (_) {
        // the server holds an equal or newer file, the local write is settled
        await _markFileUploaded(s.id, s.fileUpdatedAt);
      } on NotFoundException catch (_) {
        // the server has no row for this score, upload the metadata again first
        await _db.managers.scoresTable
            .filter((f) => f.id(s.id))
            .update((o) => o(metadataUploaded: const Value(false)));
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to upload file of score ${s.id}", e: e);
      }
    }
  }

  Future<void> _markFileUploaded(String id, DateTime fileUpdatedAt) async {
    await _db.managers.scoresTable
        .filter((f) => f.id(id) & f.fileUpdatedAt.equals(fileUpdatedAt))
        .update((o) => o(fileUploaded: const Value(true)));
  }

  Future<void> _downloadMetadataChanges() async {
    final scores = await _service.getScores(
      _con!,
      changedAfter: lastSync.value,
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
              metadataUploaded: const Value(true),
              metadataUpdatedAt: Value(s.metadataUpdatedAt.toUtc()),
              lastOpened: Value(
                s.metadataUpdatedAt.isAfter(s.fileUpdatedAt)
                    ? s.metadataUpdatedAt.toUtc()
                    : s.fileUpdatedAt.toUtc(),
              ),
              fileType: s.fileType,
              fileUpdatedAt: Value(s.fileUpdatedAt.toUtc()),
              fileDownloaded: false,
              fileUploaded: const Value(true),
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
                      ? const Value(true)
                      : const Value.absent(),
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
                      ? const Value(true)
                      : const Value.absent(),
                  fileDownloaded: fileChanged
                      ? const Value(false)
                      : const Value.absent(),
                  fileType: fileChanged
                      ? Value(s.fileType)
                      : const Value.absent(),
                  type: metadataChanged && s.type != null
                      ? Value(s.type!)
                      : const Value.absent(),
                ),
              );
          if (fileChanged) {
            deleteFile = await _scoresRepo.scoreFile(score.id, score.fileType);
          }
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

  Future<void> _downloadFileChanges() async {
    final scores = await _db.managers.scoresTable
        .filter((f) => f.fileDownloaded.isFalse())
        .get();
    for (final s in scores) {
      try {
        await _scoresRepo.createScoreDir(s.id);
        final file = await _scoresRepo.scoreFile(s.id, s.fileType);
        final partFile = File("${file.path}.part");
        await _service.downloadScoreFile(
          _con!,
          s.id,
          fileType: s.fileType,
          target: partFile,
        );

        await partFile.rename(file.path);

        await _db.managers.scoresTable
            .filter((f) => f.id(s.id))
            .update((o) => o(fileDownloaded: const Value(true)));

        await _thumbnailService.invalidateThumbnails([s.id]);
        _changedScores.add(s.id);
      } on UnauthenticatedException catch (_) {
        rethrow;
      } on StatusCodeException catch (e) {
        _itemsFailed = true;
        Log.warn("Failed to download file of score ${s.id}", e: e);
      }
    }
  }

  Future<void> _loadLastSync() async {
    lastSync.value = await _keyValue.loadDateTime(_lastSyncKey);
  }

  Future<void> _updateLastSync(DateTime? syncTime) async {
    lastSync.value = syncTime;
    if (syncTime == null) {
      await _keyValue.remove(_lastSyncKey);
    } else {
      await _keyValue.store(_lastSyncKey, syncTime);
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

  bool _shouldKeepAfterRemoteDelete({
    required DateTime? deletedAt,
    required DateTime? writtenAt,
  }) {
    if (deletedAt == null) return false;
    if (writtenAt == null) return false;
    return writtenAt.toUtc().isAfter(deletedAt.toUtc());
  }
}
