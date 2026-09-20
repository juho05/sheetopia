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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/midi/midi_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/score/pdf_view.dart';
import 'package:sheetopia/ui/score/score_page.dart';
import 'package:sheetopia/ui/score/unsupported_file_view.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String root;

  _FakePathProvider(this.root);

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getTemporaryPath() async => root;
}

const _midiChannel = "plugins.invisiblewrench.com/flutter_midi_command";

class _FakeWakelock extends WakelockPlusPlatformInterface {
  bool _enabled = false;

  @override
  Future<void> toggle({required bool enable}) async => _enabled = enable;

  @override
  Future<bool> get enabled async => _enabled;
}

class _SilentStreamHandler extends MockStreamHandler {
  final Object? initialEvent;

  _SilentStreamHandler({this.initialEvent});

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    if (initialEvent != null) events.success(initialEvent);
  }

  @override
  void onCancel(Object? arguments) {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Database db;
  late ScoresRepository scoresRepo;
  late SettingsRepository settings;

  // MidiRepository reaches for the plugin from its constructor, and a
  // poweredOff central lets its startup scan finish without a timeout
  void stubMidiPlugin() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel(_midiChannel),
      (call) async => switch (call.method) {
        "getDevices" => <dynamic>[],
        "bluetoothState" => "poweredOff",
        _ => null,
      },
    );
    for (final suffix in [
      "rx_channel",
      "setup_channel",
      "disconnect_channel",
    ]) {
      binding.defaultBinaryMessenger.setMockStreamHandler(
        EventChannel("$_midiChannel/$suffix"),
        _SilentStreamHandler(),
      );
    }
    binding.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel("$_midiChannel/bluetooth_central_state"),
      _SilentStreamHandler(initialEvent: "poweredOff"),
    );
  }

  setUp(() async {
    stubMidiPlugin();
    WakelockPlusPlatformInterface.instance = _FakeWakelock();
    tempDir = await Directory.systemTemp.createTemp("score_viewer_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    scoresRepo = ScoresRepository(db: db, thumbnailService: ThumbnailService());
    settings = SettingsRepository(
      keyValueRepository: KeyValueRepository(database: db),
    );
  });

  tearDown(() async {
    settings.dispose();
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> insertScore(String id, FileType fileType) async {
    await db.managers.scoresTable.create(
      (o) => o(
        id: id,
        title: "Title $id",
        searchText: "title $id",
        fileDownloaded: true,
        fileType: fileType,
      ),
    );
    await scoresRepo.createScoreDir(id);
    await (await scoresRepo.scoreFile(id, fileType)).writeAsString("data");
  }

  // the view model resolves the score and its file off the fake clock
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
  }

  Future<void> pumpScore(
    WidgetTester tester,
    String id,
    FileType fileType,
  ) async {
    late MidiRepository midi;
    // the database and the score directory are real IO, which the fake clock
    // of a widget test never lets finish
    await tester.runAsync(() async {
      await insertScore(id, fileType);
      midi = MidiRepository(keyValue: KeyValueRepository(database: db));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    addTearDown(midi.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScoresRepository>.value(value: scoresRepo),
          Provider<SettingsRepository>.value(value: settings),
          Provider<MidiRepository>.value(value: midi),
        ],
        child: MaterialApp(home: ScorePage(scoreId: id)),
      ),
    );
    await settle(tester);
  }

  testWidgets("an unknown file type shows the placeholder", (tester) async {
    await pumpScore(tester, "a", FileType.byName("from-the-future"));

    expect(find.byType(UnsupportedFileView), findsOneWidget);
    expect(find.byType(PdfView), findsNothing);
    expect(
      find.text("This score needs a newer version of Sheetopia."),
      findsOneWidget,
    );
    expect(find.text("File type: from-the-future"), findsOneWidget);
  });
}
