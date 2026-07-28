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
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:logger/logger.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sync/models/score_metadata.dart';
import 'package:sheetopia/data/services/sync/models/scores.dart';
import 'package:sheetopia/data/services/sync/models/server_info.dart';
import 'package:sheetopia/data/services/sync/models/setlists.dart';
import 'package:sheetopia/data/services/sync/models/tags.dart';
import 'package:sheetopia/data/services/sync/models/update_score_result.dart';
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

typedef _ScoreUpload = ({String id, DateTime? writtenAt});

class _FakeSyncService extends SyncService {
  String apiVersion = "0.3.0";
  DateTime syncTime = DateTime.utc(2026, 7, 28, 16);

  List<RemotelyDeleted> deletedScores = [];
  List<RemotelyDeleted> deletedTags = [];
  List<RemotelyDeleted> deletedSetlists = [];

  final uploadedScores = <_ScoreUpload>[];
  final uploadedTags = <_ScoreUpload>[];
  final uploadedSetlists = <_ScoreUpload>[];

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
  Future<List<RemotelyDeleted>> getDeletedScores(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedScores;

  @override
  Future<List<RemotelyDeleted>> getDeletedTags(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedTags;

  @override
  Future<List<RemotelyDeleted>> getDeletedSetlists(
    SyncConnection con, {
    DateTime? since,
  }) async => deletedSetlists;

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
  Future<UpdateScoreResultModel?> updateScore(
    SyncConnection con,
    String scoreId, {
    required String title,
    required DateTime metadataUpdatedAt,
    required List<String> tagIds,
    required ScoreMetadataModel metadata,
    DateTime? writtenAt,
  }) async {
    uploadedScores.add((id: scoreId, writtenAt: writtenAt));
    if (writtenAt == null) return null;
    return UpdateScoreResultModel(hasFile: false);
  }

  @override
  Future<void> updateTag(
    SyncConnection con,
    String tagId, {
    required String name,
    required int color,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async => uploadedTags.add((id: tagId, writtenAt: writtenAt));

  @override
  Future<void> updateSetlist(
    SyncConnection con,
    String setlistId, {
    required String name,
    required List<String> scoreIds,
    required DateTime updatedAt,
    DateTime? writtenAt,
  }) async => uploadedSetlists.add((id: setlistId, writtenAt: writtenAt));

  @override
  Future<void> deleteScore(SyncConnection con, String scoreId) async =>
      deletedOnServer.add(scoreId);

  @override
  Future<void> deleteTag(SyncConnection con, String tagId) async =>
      deletedOnServer.add(tagId);

  @override
  Future<void> deleteSetlist(SyncConnection con, String setlistId) async =>
      deletedOnServer.add(setlistId);

  @override
  Future<void> uploadScoreFile(
    SyncConnection con,
    String scoreId, {
    required File file,
    required DateTime updatedAt,
    required FileType fileType,
  }) async {}

  @override
  Future<void> downloadScoreFile(
    SyncConnection con,
    String scoreId, {
    required File target,
    required FileType fileType,
  }) async => await target.writeAsString("pdf");
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();
  // the repository logs on every kept and every discarded row
  Log.init(LogRepository());
  Log.level = Level.error;

  late Directory tempDir;
  late Database db;
  late ScoresRepository scoresRepo;
  late SetlistsRepository setlistsRepo;
  late _FakeSyncService service;
  late SyncRepository repo;

  const scoreId = "score-1";
  const tagId = "tag-1";
  const setlistId = "setlist-1";

  final deletedAt = DateTime.utc(2026, 7, 28, 15);
  final importedAt = deletedAt.add(const Duration(minutes: 5));
  final contentTime = DateTime.utc(2026, 1, 1);

  Future<void> createScore({DateTime? writtenAt, bool uploaded = true}) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: scoreId,
        title: "Title",
        searchText: " title ",
        fileDownloaded: false,
        fileType: FileType.pdf,
        lastOpened: Value(contentTime),
        metadataUpdatedAt: Value(contentTime),
        fileUpdatedAt: Value(contentTime),
        writtenAt: Value(writtenAt),
        metadataUploaded: Value(uploaded),
        fileUploaded: Value(uploaded),
      ),
    );
  }

  Future<void> createTag({DateTime? writtenAt}) async {
    await db.managers.tagsTable.create(
      (o) => o(
        id: tagId,
        name: "Tag",
        color: 1,
        updatedAt: Value(contentTime),
        writtenAt: Value(writtenAt),
        uploaded: const Value(true),
      ),
    );
  }

  Future<void> createSetlist({DateTime? writtenAt}) async {
    await db.managers.setlistsTable.create(
      (o) => o(
        id: setlistId,
        name: "Setlist",
        updatedAt: Value(contentTime),
        writtenAt: Value(writtenAt),
        uploaded: const Value(true),
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("sheetopia-sync-test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    setlistsRepo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
    service = _FakeSyncService();
    repo = SyncRepository(
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
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

  test("an imported score survives its tombstone and is resurrected", () async {
    await createScore(writtenAt: importedAt);
    service.deletedScores = [(id: scoreId, deletedAt: deletedAt)];

    await syncAndWait();

    final score = await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingleOrNull();
    expect(score, isNotNull);
    expect(
      service.uploadedScores,
      [(id: scoreId, writtenAt: importedAt)],
      reason: "the kept score must be resurrected in the same sync",
    );
  });

  test("a score with no import restore is deleted", () async {
    await createScore();
    service.deletedScores = [(id: scoreId, deletedAt: deletedAt)];

    await syncAndWait();

    final score = await db.managers.scoresTable
        .filter((f) => f.id(scoreId))
        .getSingleOrNull();
    expect(score, isNull);
    expect(service.uploadedScores, isEmpty);
  });

  test("an offline edit racing a remote deletion is discarded", () async {
    await createScore(uploaded: false);
    service.deletedScores = [(id: scoreId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.scoresTable.filter((f) => f.id(scoreId)).count(),
      0,
    );
    expect(service.uploadedScores, isEmpty);
  });

  test("a server before 0.3 keeps the unconditional delete", () async {
    service.apiVersion = "0.2.0";
    await createScore(writtenAt: importedAt);
    service.deletedScores = [(id: scoreId, deletedAt: null)];

    await syncAndWait();

    expect(
      await db.managers.scoresTable.filter((f) => f.id(scoreId)).count(),
      0,
    );
  });

  test("an import restore of a score sends its writtenAt", () async {
    await createScore(writtenAt: importedAt, uploaded: false);

    await syncAndWait();

    expect(service.uploadedScores, [(id: scoreId, writtenAt: importedAt)]);
  });

  test("an ordinary local edit sends no writtenAt at all", () async {
    await createScore(uploaded: false);
    await createTag();
    await db.managers.tagsTable
        .filter((f) => f.id(tagId))
        .update((o) => o(uploaded: const Value(false)));
    await createSetlist();
    await db.managers.setlistsTable
        .filter((f) => f.id(setlistId))
        .update((o) => o(uploaded: const Value(false)));

    await syncAndWait();

    expect(service.uploadedScores, [(id: scoreId, writtenAt: null)]);
    expect(service.uploadedTags, [(id: tagId, writtenAt: null)]);
    expect(service.uploadedSetlists, [(id: setlistId, writtenAt: null)]);
  });

  test("an imported tag survives its tombstone and keeps its scores", () async {
    await createScore();
    await createTag(writtenAt: importedAt);
    await db.managers.scoreTagsTable.create(
      (o) => o(score: scoreId, tag: tagId),
    );
    service.deletedTags = [(id: tagId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(await db.managers.tagsTable.filter((f) => f.id(tagId)).count(), 1);
    expect(
      await db.managers.scoreTagsTable.filter((f) => f.tag.id(tagId)).count(),
      1,
    );
    expect(service.uploadedTags, [(id: tagId, writtenAt: importedAt)]);
  });

  test("a tag with no import restore loses its assignments too", () async {
    await createScore();
    await createTag();
    await db.managers.scoreTagsTable.create(
      (o) => o(score: scoreId, tag: tagId),
    );
    service.deletedTags = [(id: tagId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(await db.managers.tagsTable.filter((f) => f.id(tagId)).count(), 0);
    expect(
      await db.managers.scoreTagsTable.filter((f) => f.tag.id(tagId)).count(),
      0,
    );
  });

  test("an imported setlist survives its tombstone", () async {
    await createSetlist(writtenAt: importedAt);
    service.deletedSetlists = [(id: setlistId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.setlistsTable.filter((f) => f.id(setlistId)).count(),
      1,
    );
    expect(service.uploadedSetlists, [(id: setlistId, writtenAt: importedAt)]);
  });

  test("a setlist with no import restore is deleted", () async {
    await createSetlist();
    service.deletedSetlists = [(id: setlistId, deletedAt: deletedAt)];

    await syncAndWait();

    expect(
      await db.managers.setlistsTable.filter((f) => f.id(setlistId)).count(),
      0,
    );
    expect(service.uploadedSetlists, isEmpty);
  });
}
