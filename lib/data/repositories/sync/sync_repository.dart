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
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/version/version.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

enum SyncState { none, failure, syncing, success }

class SyncRepository {
  static const _defaultSyncDelay = Duration(seconds: 30);

  static const minAPIVersionSetlist = Version(major: 0, minor: 2);

  final ScoresRepository _scoresRepo;
  final SetlistsRepository _setlistsRepo;
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

  static const String _userKey = "auth.user";
  static const String _conKey = "sheetopia/auth.con";

  SyncConnection? _con;
  String? _user;

  bool get signedIn => _con != null;

  String get user => _user ?? "unknown";

  Uri get serverUri => _con!.baseUri;

  AppLifecycleListener? _listener;

  SyncRepository({
    required ScoresRepository scoresRepo,
    required SetlistsRepository setlistsRepo,
    required KeyValueRepository keyValue,
    required Database db,
    required SyncService syncService,
    required ThumbnailService thumbnailService,
  }) : _scoresRepo = scoresRepo,
       _setlistsRepo = setlistsRepo,
       _keyValue = keyValue,
       _db = db,
       _service = syncService,
       _thumbnailService = thumbnailService,
       _encryptedStorage = Platform.isLinux
           ? EncryptedStorageLinux(keyValueRepo: keyValue)
           : EncryptedStorageSecureStorage() {
    _load().then((value) {
      _scoresRepo.locallyUpdatedScoreIds.listen((event) => _requestSync());
      _scoresRepo.locallyUpdatedTagIds.listen((event) => _requestSync());
      _setlistsRepo.locallyUpdatedSetlistIds.listen((event) => _requestSync());
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
  }

  Future<void> _load() async {
    final conStr = await _encryptedStorage.read(_conKey);
    if (conStr == null) {
      await _keyValue.remove(_conKey);
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

  void _requestSync() {
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

    try {
      if (lastSync.value == null) {
        await _loadLastSync();
      }

      final serverInfo = await _service.getServerInfo(_con!.baseUri);
      final syncTime = serverInfo.time;
      final apiVersion = Version.parse(serverInfo.apiVersion);

      await _uploadDeletedTags();
      await _uploadDeletedScores();
      if (apiVersion >= minAPIVersionSetlist) {
        await _uploadDeletedSetlists();
      }

      await _downloadDeletedTags();

      await _uploadTagChanges();
      await _downloadTagChanges();

      await _downloadDeletedScores();

      await _uploadMetadataChanges();
      await _uploadFileChanges();

      await _downloadMetadataChanges();
      await _downloadFileChanges();

      if (apiVersion >= minAPIVersionSetlist) {
        await _downloadDeletedSetlists();
        await _uploadSetlistChanges();
        await _downloadSetlistChanges();
      }

      await _updateLastSync(syncTime);

      state.value = SyncState.success;
    } on UnauthenticatedException catch (_) {
      await logout();
    } catch (e, st) {
      if (signedIn) {
        print("Sync failed: $e\n$st");
        state.value = SyncState.failure;
      }
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _setlistsRepo.remoteChangedSetlists(_changedSetlists);
      _changedTags = {};
      _changedScores = {};
      _changedSetlists = {};
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

  Future<void> _downloadDeletedSetlists() async {
    final deletedSetlistIds = await _service.getDeletedSetlistIds(
      _con!,
      since: lastSync.value,
    );
    for (final s in deletedSetlistIds) {
      final count = await _db.managers.setlistsTable
          .filter((f) => f.id(s))
          .delete();
      if (count > 0) {
        _changedSetlists.add(s);
      }
    }
  }

  Future<void> _uploadSetlistChanges() async {
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
        );
        await _db.managers.setlistsTable
            .filter((f) => f.id(s.id) & f.updatedAt.equals(s.updatedAt))
            .update((o) => o(uploaded: const Value(true)));
      } on ConflictException catch (_) {
        // local changes aren't the latest version
      }
    }
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

  Future<void> _downloadDeletedTags() async {
    final deletedTagIds = await _service.getDeletedTagIds(
      _con!,
      since: lastSync.value,
    );
    for (final t in deletedTagIds) {
      await _db.transaction(() async {
        final affectedScores = await _db.managers.scoreTagsTable
            .filter((f) => f.tag.id(t))
            .get();
        _changedScores.addAll(affectedScores.map((s) => s.score));

        await _db.managers.scoreTagsTable.filter((f) => f.tag.id(t)).delete();
        final count = await _db.managers.tagsTable
            .filter((f) => f.id(t))
            .delete();
        if (count > 0) {
          _changedTags.add(t);
        }
      });
    }
  }

  Future<void> _uploadTagChanges() async {
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
        );
        await _db.managers.tagsTable
            .filter((f) => f.id(t.id) & f.updatedAt.equals(t.updatedAt))
            .update((o) => o(uploaded: const Value(true)));
      } on ConflictException catch (_) {
        // local changes aren't the latest version
      }
    }
  }

  Future<void> _downloadTagChanges() async {
    final tags = await _service.getTags(_con!, changedAfter: lastSync.value);
    for (final t in tags) {
      final result = await _db.managers.tagsTable.createReturningOrNull(
        (o) => o(
          id: t.id,
          name: t.name,
          color: t.color,
          updatedAt: Value(t.updatedAt.toUtc()),
          uploaded: const Value(true),
        ),
        onConflict: DoUpdate.withExcluded(
          (old, excluded) => TagsTableCompanion.custom(
            name: excluded.name,
            color: excluded.color,
            uploaded: excluded.uploaded,
            updatedAt: excluded.updatedAt,
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

  Future<void> _downloadDeletedScores() async {
    final deletedScores = await _service.getDeletedScoreIds(
      _con!,
      since: lastSync.value,
    );
    final actuallyDeleted = <String>{};
    for (final s in deletedScores) {
      final count = await _db.managers.scoresTable
          .filter((f) => f.id(s))
          .delete();
      await _scoresRepo.cleanupScoreFilesAfterDelete(s);
      if (count > 0) {
        _changedScores.add(s);
        actuallyDeleted.add(s);
      }
    }
    _scoresRepo.announceDeletedScores(actuallyDeleted);
  }

  Future<void> _uploadMetadataChanges() async {
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
        await _service.updateScore(
          _con!,
          s.id,
          title: s.title,
          metadataUpdatedAt: s.metadataUpdatedAt.toUtc(),
          tagIds: (refs.scoreTagsTableRefs.prefetchedData ?? [])
              .map((t) => t.tag)
              .toList(),
          metadata: ScoreMetadataModel(
            composer: s.composer ?? "",
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
      } on ConflictException catch (_) {
        // local changes aren't the latest version
      }
      await _db.managers.scoresTable
          .filter(
            (f) => f.id(s.id) & f.metadataUpdatedAt.equals(s.metadataUpdatedAt),
          )
          .update((o) => o(metadataUploaded: const Value(true)));
    }
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
      } on ConflictException catch (_) {
        // local file is no longer the latest version
      }
      await _db.managers.scoresTable
          .filter((f) => f.id(s.id) & f.fileUpdatedAt.equals(s.fileUpdatedAt))
          .update((o) => o(fileUploaded: const Value(true)));
    }
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
            await _db.managers.scoreTagsTable.bulkCreate(
              (o) => s.tagIds.map((t) => o(score: s.id, tag: t)),
            );
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

  Future<void> _downloadFileChanges() async {
    final scores = await _db.managers.scoresTable
        .filter((f) => f.fileDownloaded.isFalse())
        .get();
    for (final s in scores) {
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

  Value<String?> _annotationsColumnValue(Map<String, dynamic>? a) {
    if (a == null) return const Value.absent();
    if (a.isEmpty) return const Value(null);
    return Value(jsonEncode(a));
  }
}
