import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

enum SyncState { none, failure, syncing, success }

class SyncRepository {
  static const _defaultSyncDelay = Duration(seconds: 30);

  final ScoresRepository _scoresRepo;
  final KeyValueRepository _keyValue;
  final Database _db;
  final SyncService _service;
  final ThumbnailService _thumbnailService;

  final ValueNotifier<SyncState> state = ValueNotifier(SyncState.none);

  static const String _lastSyncKey = "last_sync";
  DateTime? _lastSync;
  Set<String> _changedScores = {};
  Set<String> _changedTags = {};

  // TODO replace with actual credentials
  static final _con = SyncConnection(
    baseUri: Uri.parse("http://localhost:8080"),
    authKey: "uf9Zng1T3FV58i3GmRi1x2Dy3Fwnh8TyYB9UnXnKLMhbscpXVTRizaDG6uyERpsR",
  );

  SyncRepository({
    required ScoresRepository scoresRepo,
    required KeyValueRepository keyValue,
    required Database db,
    required SyncService syncService,
    required ThumbnailService thumbnailService,
  }) : _scoresRepo = scoresRepo,
       _keyValue = keyValue,
       _db = db,
       _service = syncService,
       _thumbnailService = thumbnailService {
    _load().then((value) {
      _scoresRepo.locallyUpdatedScoreIds.listen((event) => _requestSync());
      _scoresRepo.locallyUpdatedTagIds.listen((event) => _requestSync());
    });
  }

  Future<void> login({required String user, required String password}) async {
    // TODO

    _sync();
  }

  Future<void> logout() async {
    // TODO delete auth state

    _syncTimer?.cancel();
    _syncTimer = null;
    _nextSyncDelay = _defaultSyncDelay;
    state.value = SyncState.none;
  }

  Future<void> _load() async {
    // TODO load auth state
    _sync();
  }

  void _requestSync() {
    // TODO ignore if not logged in
    _nextSyncDelay = const Duration(seconds: 5);
    if (state.value != SyncState.syncing) {
      _scheduleSync();
    }
  }

  Duration _nextSyncDelay = _defaultSyncDelay;
  Timer? _syncTimer;

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(_nextSyncDelay, () {
      _syncTimer = null;
      _nextSyncDelay = _defaultSyncDelay;
      _sync();
    });
  }

  // TODO implement proper scheduling
  Future<bool> _sync() async {
    if (state.value == SyncState.syncing) return false;
    state.value = SyncState.syncing;

    try {
      if (_lastSync == null) {
        await _loadLastSync();
      }

      final syncTime = (await _service.getServerInfo(_con.baseUri)).time;

      await _uploadDeletedTags();
      await _uploadDeletedScores();

      await _downloadDeletedTags();

      await _uploadTagChanges();
      await _downloadTagChanges();

      await _downloadDeletedScores();

      await _uploadMetadataChanges();
      await _uploadFileChanges();

      await _downloadMetadataChanges();
      await _downloadFileChanges();

      await _updateLastSync(syncTime);

      state.value = SyncState.success;
    } on UnauthenticatedException catch (_) {
      await logout();
    } catch (e, st) {
      print("Sync failed: $e\n$st");
      state.value = SyncState.failure;
    } finally {
      _scoresRepo.remoteChangedTags(_changedTags);
      _scoresRepo.remoteChangedScores(_changedScores);
      _changedTags = {};
      _changedScores = {};
      _scheduleSync();
    }
    return true;
  }

  Future<void> _uploadDeletedTags() async {
    final startTime = DateTime.now();
    final deletedTagIds = (await _db.managers.deletedTagsTable.get()).map(
      (t) => t.tagId,
    );

    for (final tagId in deletedTagIds) {
      try {
        await _service.deleteTag(_con, tagId);
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
        await _service.deleteScore(_con, scoreId);
      } on NotFoundException catch (_) {
        // score is already deleted on server or was never synced
      }
    }

    await _db.managers.deletedScoresTable
        .filter((f) => f.deletedAt.isBeforeOrOn(startTime))
        .delete();
  }

  Future<void> _downloadDeletedTags() async {
    final deletedTagIds = await _service.getDeletedTagIds(
      _con,
      since: _lastSync,
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
          _con,
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
    final tags = await _service.getTags(_con, changedAfter: _lastSync);
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
      _con,
      since: _lastSync,
    );
    for (final s in deletedScores) {
      final count = await _db.managers.scoresTable
          .filter((f) => f.id(s))
          .delete();
      if (count > 0) {
        _changedScores.add(s);
      }
    }
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
          _con,
          s.id,
          title: s.title,
          metadataUpdatedAt: s.metadataUpdatedAt.toUtc(),
          tagIds: (refs.scoreTagsTableRefs.prefetchedData ?? [])
              .map((t) => t.tag)
              .toList(),
          metadata: ScoreMetadataModel(
            composer: s.composer ?? "",
            genres: (refs.genresTableRefs.prefetchedData ?? [])
                .map((g) => g.genre)
                .toList(),
            instruments: (refs.instrumentsTableRefs.prefetchedData ?? [])
                .map((i) => i.instrument)
                .toList(),
          ),
        );
        await _db.managers.scoresTable
            .filter(
              (f) =>
                  f.id(s.id) & f.metadataUpdatedAt.equals(s.metadataUpdatedAt),
            )
            .update((o) => o(metadataUploaded: const Value(true)));
      } on ConflictException catch (_) {
        // local changes aren't the latest version
      }
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
          _con,
          s.id,
          file: file,
          updatedAt: s.fileUpdatedAt.toUtc(),
          fileType: s.fileType,
        );
        await _db.managers.scoresTable
            .filter((f) => f.id(s.id) & f.fileUpdatedAt.equals(s.fileUpdatedAt))
            .update((o) => o(fileUploaded: const Value(true)));
      } on ConflictException catch (_) {
        // local file is no longer the latest version
      }
    }
  }

  Future<void> _downloadMetadataChanges() async {
    final scores = await _service.getScores(_con, changedAfter: _lastSync);

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
              metadataUploaded: const Value(true),
              metadataUpdatedAt: Value(s.metadataUpdatedAt.toUtc()),
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
        }
      });

      if (deleteFile != null) {
        try {
          await deleteFile!.delete();
        } catch (_) {}
      }
      _changedScores.add(s.id);
    }
  }

  Future<void> _downloadFileChanges() async {
    final scores = await _db.managers.scoresTable
        .filter((f) => f.fileDownloaded.isFalse())
        .get();
    for (final s in scores) {
      final file = await _scoresRepo.scoreFile(s.id, s.fileType);
      final partFile = File("${file.path}.part");
      await _service.downloadScoreFile(
        _con,
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
    _lastSync = await _keyValue.loadDateTime(_lastSyncKey);
  }

  Future<void> _updateLastSync(DateTime? syncTime) async {
    _lastSync = syncTime;
    await _keyValue.store(_lastSyncKey, syncTime);
  }

  Value<String?> _optionalStringValue(String? str) {
    if (str == null) return const Value.absent();
    if (str == "") return const Value(null);
    return Value(str);
  }
}
