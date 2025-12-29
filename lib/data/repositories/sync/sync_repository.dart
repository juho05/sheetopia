import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/sync/exceptions.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/sync_connection.dart';
import 'package:sheetopia/data/services/sync/sync_service.dart';

enum SyncState { none, failure, syncing, success }

class SyncRepository {
  final ScoresRepository _scoresRepo;
  final KeyValueRepository _keyValue;
  final Database _db;
  final SyncService _service;

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
  }) : _scoresRepo = scoresRepo,
       _keyValue = keyValue,
       _db = db,
       _service = syncService {
    _sync();
  }

  // TODO sync local updates quickly without full sync

  // TODO implement proper scheduling
  Future<void> _sync() async {
    if (state.value == SyncState.syncing) return;
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
      // TODO logout
      print("Unauthenticated!");
      state.value = SyncState.none;
    } catch (e, st) {
      print("Sync failed: $e\n$st");
      state.value = SyncState.failure;
    } finally {
      _scoresRepo.changedTags(_changedTags);
      _scoresRepo.changedScores(_changedScores);
      _changedTags = {};
      _changedScores = {};
    }
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
    // TODO download all new deleted tags and delete them locally
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
          updatedAt: t.updatedAt,
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
    // TODO download all new updated tags and update them locally
  }

  Future<void> _downloadDeletedScores() async {
    // TODO download all new deleted scores and delete them locally
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
          metadataUpdatedAt: s.metadataUpdatedAt,
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
          updatedAt: s.fileUpdatedAt,
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
    // TODO download all new updated scores and update them locally, set downloaded to false if fileUpdatedAt changed
    // REMEMBER received data: null fields -> ignore, zero value -> set to null
  }

  Future<void> _downloadFileChanges() async {
    // TODO delete all files of scores with downloaded == false
    // TODO download files for scores with downloaded == false and set downloaded to true
  }

  Future<void> _loadLastSync() async {
    _lastSync = await _keyValue.loadDateTime(_lastSyncKey);
  }

  Future<void> _updateLastSync(DateTime syncTime) async {
    _lastSync = syncTime;
    await _keyValue.store(_lastSyncKey, syncTime);
  }
}
