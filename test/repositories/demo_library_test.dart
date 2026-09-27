/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:sheetopia/data/services/sync/sync_service.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';

const _archive = "tool/demo_library/out/sheetopia-demo-library.zip";

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
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => XFile(File(_archive).absolute.path);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  final skip = File(_archive).existsSync()
      ? false
      : "demo library not built, run tool/demo_library/build.py";

  late Directory tempDir;
  late Database db;
  late ImportExportRepository repo;

  List<dynamic> archived(String name) {
    final archive = ZipDecoder().decodeBytes(File(_archive).readAsBytesSync());
    return jsonDecode(utf8.decode(archive.findFile(name)!.content))
        as List<dynamic>;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp("demo_library_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    FileSelectorPlatform.instance = _FakeFileSelector();

    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    final scoresRepo = ScoresRepository(
      db: db,
      thumbnailService: ThumbnailService(),
    );
    final setlistsRepo = SetlistsRepository(db: db, scoresRepo: scoresRepo);
    final practiceRepo = PracticeRepository(db: db, scoresRepo: scoresRepo);
    repo = ImportExportRepository(
      thumbnailService: ThumbnailService(),
      scoresRepo: scoresRepo,
      setlistsRepo: setlistsRepo,
      practiceRepo: practiceRepo,
      syncRepo: SyncRepository(
        scoresRepo: scoresRepo,
        setlistsRepo: setlistsRepo,
        practiceRepo: practiceRepo,
        keyValue: KeyValueRepository(database: db),
        db: db,
        syncService: SyncService(),
        thumbnailService: ThumbnailService(),
        encryptedStorage: _InMemoryEncryptedStorage(),
      ),
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test("the demo library imports completely", skip: skip, () async {
    expect(await repo.import(), isTrue);

    final scores = await db.managers.scoresTable.get();
    expect(scores, hasLength(archived("scores.json").length));
    expect(scores.where((s) => s.annotations != null), isNotEmpty);
    expect(scores.where((s) => s.type == ScoreType.exercise), isNotEmpty);

    final tags = await db.managers.tagsTable.get();
    expect(tags, hasLength(archived("tags.json").length));
    expect(tags.where((t) => t.type == TagType.exercise), isNotEmpty);

    expect(
      await db.managers.setlistsTable.count(),
      archived("setlists.json").length,
    );
    expect(
      await db.managers.exerciseCategoriesTable.count(),
      archived("exercise_categories.json").length,
    );
    expect(
      await db.managers.exercisesTable.count(),
      archived("exercises.json").length,
    );
    expect(
      await db.managers.practiceRoutinesTable.count(),
      archived("practice_routines.json").length,
    );
    expect(
      await db.managers.practiceRecordsTable.count(),
      archived("practice_records.json").length,
    );

    final exercises = archived("exercises.json");
    final linkedScores = exercises.fold<int>(
      0,
      (sum, e) => sum + (e["scoreIds"] as List).length,
    );
    expect(await db.managers.exerciseScoresTable.count(), linkedScores);
    final exerciseTags = exercises.fold<int>(
      0,
      (sum, e) => sum + (e["tagIds"] as List).length,
    );
    expect(await db.managers.exerciseTagsTable.count(), exerciseTags);

    final entries = archived(
      "practice_routines.json",
    ).fold<int>(0, (sum, r) => sum + (r["entries"] as List).length);
    expect(await db.managers.practiceRoutineEntriesTable.count(), entries);
  });

  test("re-importing the demo library changes nothing", skip: skip, () async {
    expect(await repo.import(), isTrue);
    final before = await db.managers.practiceRecordsTable.count();
    expect(await repo.import(), isTrue);
    expect(await db.managers.practiceRecordsTable.count(), before);
    expect(
      await db.managers.scoresTable.count(),
      archived("scores.json").length,
    );
  });
}
