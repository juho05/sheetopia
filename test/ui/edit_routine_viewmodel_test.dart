/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_routine.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/services/database/database.dart';
import 'package:sheetopia/data/services/thumbnail_service.dart';
import 'package:sheetopia/ui/practice/edit_routine_viewmodel.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late PracticeRepository repo;

  Future<String> createExercise(String name) => repo.createExercise(
    name: name,
    description: "",
    instrument: "",
    source: "",
    sourceLink: "",
    tagIds: const [],
  );

  Future<PracticeRoutineEntry> entry(
    String exerciseId, {
    Duration? targetDuration,
  }) async => PracticeRoutineEntry(
    id: repo.newRoutineEntryId(),
    exercise: (await repo.getExercisesById([exerciseId]))[exerciseId]!,
    targetDuration: targetDuration,
  );

  EditRoutineViewModel viewModelFor(String? routineId) {
    final viewModel = EditRoutineViewModel(repo: repo, routineId: routineId);
    addTearDown(viewModel.dispose);
    return viewModel;
  }

  Future<EditRoutineViewModel> loadedViewModel(String routineId) async {
    final viewModel = viewModelFor(routineId);
    await Future.delayed(Duration.zero);
    expect(viewModel.loading, isFalse);
    return viewModel;
  }

  void setName(EditRoutineViewModel viewModel, String name) {
    viewModel.form.control(EditRoutineViewModel.formName).value = name;
  }

  void setDescription(EditRoutineViewModel viewModel, String description) {
    viewModel.form.control(EditRoutineViewModel.formDescription).value =
        description;
  }

  setUp(() async {
    db = Database(NativeDatabase.memory());
    await db.customStatement("PRAGMA foreign_keys = ON");
    repo = PracticeRepository(
      db: db,
      scoresRepo: ScoresRepository(
        db: db,
        thumbnailService: ThumbnailService(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test("a new routine is only written on create", () async {
    final exerciseId = await createExercise("Chromatic");
    final viewModel = viewModelFor(null);
    expect(viewModel.isCreate, isTrue);
    expect(viewModel.loading, isFalse);

    setName(viewModel, "Morning");
    setDescription(viewModel, "Every day");
    await viewModel.addExercises([exerciseId]);
    viewModel.setTargetDuration(
      viewModel.entries.single.id,
      const Duration(minutes: 20),
    );
    await Future.delayed(const Duration(milliseconds: 300));

    expect(await db.managers.practiceRoutinesTable.count(), 0);
    expect(await db.managers.practiceRoutineEntriesTable.count(), 0);

    await viewModel.create();

    final routines = await repo.getRoutines(size: 10);
    final routine = await repo.getRoutine(routines.single.id);
    expect(routine!.name, "Morning");
    expect(routine.description, "Every day");
    expect(routine.entries.single.exercise.name, "Chromatic");
    expect(routine.entries.single.targetDuration, const Duration(minutes: 20));
    expect(routine.entries.single.id, viewModel.entries.single.id);
  });

  test("create is rejected without a name", () async {
    final viewModel = viewModelFor(null);

    expect(viewModel.create, throwsStateError);
  });

  test("an existing routine is loaded into the form", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "Every day",
      entries: [
        await entry(exerciseId, targetDuration: const Duration(minutes: 5)),
      ],
    );

    final viewModel = await loadedViewModel(routineId);

    expect(viewModel.isCreate, isFalse);
    expect(viewModel.missing, isFalse);
    expect(viewModel.name, "Morning");
    expect(
      viewModel.form.control(EditRoutineViewModel.formDescription).value,
      "Every day",
    );
    expect(viewModel.entries.single.exercise.name, "Chromatic");
    expect(viewModel.targetDuration, const Duration(minutes: 5));
  });

  test("a routine that no longer exists is reported", () async {
    final viewModel = viewModelFor("nope");
    await Future.delayed(Duration.zero);

    expect(viewModel.missing, isTrue);
    expect(viewModel.loading, isFalse);
  });

  test("the values are saved after the debounce", () async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    final viewModel = await loadedViewModel(routineId);

    setName(viewModel, "Evening");
    expect((await repo.getRoutine(routineId))!.name, "Morning");

    await Future.delayed(const Duration(milliseconds: 300));

    expect((await repo.getRoutine(routineId))!.name, "Evening");
  });

  test("added exercises are stored right away", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    final viewModel = await loadedViewModel(routineId);

    await viewModel.addExercises([first, second]);

    expect(viewModel.entries.map((e) => e.exercise.name), [
      "Chromatic",
      "Thirds",
    ]);
    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.map((e) => e.exercise.name), [
      "Chromatic",
      "Thirds",
    ]);
  });

  test("moving an entry keeps its id", () async {
    final first = await createExercise("Chromatic");
    final second = await createExercise("Thirds");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(first), await entry(second)],
    );
    final viewModel = await loadedViewModel(routineId);
    final ids = viewModel.entries.map((e) => e.id).toList();

    await viewModel.moveEntry(1, 0);

    expect(viewModel.entries.map((e) => e.id), [ids[1], ids[0]]);
    final routine = await repo.getRoutine(routineId);
    expect(routine!.entries.map((e) => e.id), [ids[1], ids[0]]);
    expect(routine.entries.map((e) => e.exercise.name), [
      "Thirds",
      "Chromatic",
    ]);
  });

  test("a removed entry is deleted", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );
    final viewModel = await loadedViewModel(routineId);

    await viewModel.removeEntry(viewModel.entries.single.id);

    expect(viewModel.entries, isEmpty);
    expect((await repo.getRoutine(routineId))!.entries, isEmpty);
  });

  test("the target duration is saved after the debounce", () async {
    final exerciseId = await createExercise("Chromatic");
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
      entries: [await entry(exerciseId)],
    );
    final viewModel = await loadedViewModel(routineId);
    final entryId = viewModel.entries.single.id;

    viewModel.setTargetDuration(entryId, const Duration(minutes: 15));
    expect(viewModel.targetDuration, const Duration(minutes: 15));
    expect(
      (await repo.getRoutine(routineId))!.entries.single.targetDuration,
      isNull,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    expect(
      (await repo.getRoutine(routineId))!.entries.single.targetDuration,
      const Duration(minutes: 15),
    );
    expect((await repo.getRoutine(routineId))!.entries.single.id, entryId);
  });

  test("a deleted routine is gone", () async {
    final routineId = await repo.createRoutine(
      name: "Morning",
      description: "",
    );
    final viewModel = await loadedViewModel(routineId);

    await viewModel.delete();

    expect(await repo.getRoutine(routineId), isNull);
  });
}
