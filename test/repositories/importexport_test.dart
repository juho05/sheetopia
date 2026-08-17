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
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sheetopia/data/repositories/encrypted_storage/encrypted_storage.dart';
import 'package:sheetopia/data/repositories/importexport/importexport_repository.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/setlists/setlists_repository.dart';
import 'package:sheetopia/data/repositories/sync/sync_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
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
  late SyncRepository syncRepo;
  late ImportExportRepository repo;
  late _FakeFileSelector fileSelector;

  const scoreId = "score-1";
  const tagId = "tag-1";
  const setlistId = "setlist-1";

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
    syncRepo = SyncRepository(
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
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
}
