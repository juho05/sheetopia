/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/keyvalue/key_value_repository.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/practice/exercise.dart';
import 'package:sheetopia/data/repositories/scores/difficulty.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/ui/common/difficulty.dart';
import 'package:sheetopia/ui/practice/exercise_tile.dart';

void main() {
  Log.init(LogRepository());

  late Database db;
  late SettingsRepository settings;

  setUp(() {
    db = Database(NativeDatabase.memory());
    settings = SettingsRepository(
      keyValueRepository: KeyValueRepository(database: db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<SettingsRepository>.value(
        value: settings,
        child: const MaterialApp(
          home: Scaffold(
            body: ExerciseTile(
              exercise: Exercise(
                id: "a",
                name: "Scales",
                category: null,
                instrument: null,
                tags: [],
                description: null,
                difficulty: Difficulty.hard,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("the difficulty icon follows the setting", (tester) async {
    await pumpTile(tester);
    expect(find.byType(DifficultyIcon), findsNothing);

    settings.appearanceSettings.cardDifficulty = true;
    await tester.pump();
    expect(find.byType(DifficultyIcon), findsOneWidget);
    expect(find.byTooltip("Hard"), findsOneWidget);
  });
}
