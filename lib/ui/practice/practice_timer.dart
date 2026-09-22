/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_record.dart';
import 'package:sheetopia/utils/app_shutdown.dart';

enum PracticeTimerState { idle, running, paused }

enum PracticeRecoveryChoice { discard, untilLeft, untilNow }

class PracticeRecovery {
  final Duration counted;

  final DateTime leftAt;

  final Duration gap;

  const PracticeRecovery({
    required this.counted,
    required this.leftAt,
    required this.gap,
  });
}

class PracticeTimer extends ChangeNotifier {
  static const Duration checkpointInterval = Duration(seconds: 5);

  /// Below these gaps the time away is counted without asking.
  static const Duration minGapWithTarget = Duration(minutes: 5);
  static const Duration minGapWithoutTarget = Duration(minutes: 10);

  /// With a target duration the gap is only questioned once it pushes the
  /// exercise this far past its target.
  static const double targetOvershoot = 1.1;

  final PracticeRepository _repo;

  String? _routineId;

  /// Whether an exercise was practiced since the page was opened.
  bool _touched = false;

  String? _exerciseId;
  String? _routineEntryId;
  Duration? _target;

  PracticeRecord? _record;

  /// Time practiced for this exercise in the current progress outside of
  /// [_record].
  Duration _carry = Duration.zero;

  PracticeTimerState _state = PracticeTimerState.idle;

  PracticeRecovery? _recovery;

  bool _resolving = false;

  int _showGeneration = 0;

  Timer? _ticker;

  static const Duration _tickSlack = Duration(milliseconds: 8);

  final ValueNotifier<int> _ticks = ValueNotifier(0);

  /// Whether the engine is going away, a dispose then closes the app, not the
  /// page.
  bool _detached = false;

  late final AppLifecycleListener _lifecycle;

  bool _disposed = false;

  PracticeTimer({required this._repo}) {
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
  }

  Listenable get ticks => _ticks;

  PracticeTimerState get state => _state;

  bool get running => _state == PracticeTimerState.running;

  bool get paused => _state == PracticeTimerState.paused;

  bool get started => _state != PracticeTimerState.idle;

  bool get ready => _exerciseId != null && !_resolving;

  PracticeRecovery? get recovery => _recovery;

  Duration? get target => _target;

  Duration get elapsed {
    final record = _record;
    if (record == null) return _carry;
    if (_state == PracticeTimerState.idle) return _carry + record.duration;
    return _carry + record.elapsedAt(DateTime.now());
  }

  bool get overTarget {
    final target = _target;
    return target != null && target > Duration.zero && elapsed > target;
  }

  Future<void> show({
    required String exerciseId,
    String? routineId,
    String? routineEntryId,
    Duration? target,
  }) async {
    if (_disposed) return;
    final generation = ++_showGeneration;
    _stopTicker();
    _resolving = true;
    _state = PracticeTimerState.idle;
    _notify();
    await _stopRecord();
    _routineId = routineId;
    _exerciseId = exerciseId;
    _routineEntryId = routineEntryId;
    _target = target;
    _record = null;
    _recovery = null;
    _carry = Duration.zero;
    try {
      await _recoverRunningRecord();
      if (_disposed) return;
      await _reloadCarry();
      if (_disposed) return;
      final record = _record;
      if (record != null) await _handleGap(record, record.runningSince!);
    } finally {
      if (generation == _showGeneration) _resolving = false;
    }
    _notify();
  }

  /// Only one stopwatch runs at a time. One left running for this exercise is
  /// adopted, one left running elsewhere is stopped at its last checkpoint.
  Future<void> _recoverRunningRecord() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null) return;
    while (!_disposed) {
      final running = await _repo.getRunningRecord();
      if (running == null) return;
      if (running.routineId == _routineId &&
          running.matches(
            exerciseId: exerciseId,
            routineEntryId: _routineEntryId,
          )) {
        _record = running;
        _touched = true;
        return;
      }
      await _repo.checkpointRecord(
        running,
        now: running.runningSince,
        stop: true,
      );
    }
  }

  Future<void> start() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null || running) return;
    _touched = true;
    _record = await _repo.startRecord(
      exerciseId: exerciseId,
      routineId: _routineId,
      routineEntryId: _routineEntryId,
    );
    await _reloadCarry();
    _state = PracticeTimerState.running;
    _startTicker();
    _notify();
  }

  Future<void> resetProgress() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null || running || !ready) return;
    final routineId = _routineId;
    if (routineId == null) {
      await _repo.resetExerciseProgress(exerciseId);
    } else {
      await _repo.resetRoutineProgress(routineId);
    }
    _record = null;
    _carry = Duration.zero;
    await start();
  }

  Future<void> pause() async {
    if (!running) return;
    _stopTicker();
    _state = PracticeTimerState.paused;
    await _checkpoint(stop: true);
    _notify();
  }

  Future<void> resume() => start();

  Future<void> close() async {
    _stopTicker();
    if (!_touched) return;
    if (appIsClosing || _detached) {
      if (_recovery == null) await _checkpoint(publish: true);
      return;
    }
    await _stopRecord();
  }

  Future<void> resolveRecovery(PracticeRecoveryChoice choice) async {
    final record = _record;
    final recovery = _recovery;
    if (record == null || recovery == null) return;
    switch (choice) {
      case PracticeRecoveryChoice.discard:
        await _repo.discardRecord(record);
        _record = null;
        _state = PracticeTimerState.idle;
      case PracticeRecoveryChoice.untilLeft:
        _record = await _repo.checkpointRecord(
          record,
          now: recovery.leftAt,
          stop: true,
        );
        _state = PracticeTimerState.idle;
      case PracticeRecoveryChoice.untilNow:
        await _checkpoint(publish: true);
        _state = PracticeTimerState.running;
        _startTicker();
    }
    _recovery = null;
    _notify();
  }

  static Duration tickDelay(Duration elapsed) {
    final into = elapsed.inMicroseconds % Duration.microsecondsPerSecond;
    return Duration(microseconds: Duration.microsecondsPerSecond - into) +
        _tickSlack;
  }

  void _startTicker() => _scheduleTick();

  void _scheduleTick() {
    _ticker?.cancel();
    if (!running) return;
    _ticker = Timer(tickDelay(elapsed), _onTick);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    final runningSince = _record?.runningSince;
    if (runningSince != null &&
        DateTime.now().difference(runningSince) >= checkpointInterval) {
      unawaited(_checkpoint());
    }
    _tick();
    _scheduleTick();
  }

  void _tick() {
    if (_disposed) return;
    _ticks.value++;
  }

  Future<void> _checkpoint({bool stop = false, bool publish = false}) async {
    final record = _record;
    if (record == null) return;
    final next = await _repo.checkpointRecord(
      record,
      stop: stop,
      publish: publish,
    );
    _record = next;
    // the stopwatch ran over midnight and continues in a new record
    if (next.id != record.id) await _reloadCarry();
    _tick();
  }

  Future<void> _stopRecord() async {
    final record = _record;
    if (record == null) return;
    _record = await _repo.checkpointRecord(
      record,
      now: _recovery?.leftAt,
      stop: true,
    );
    _state = PracticeTimerState.idle;
  }

  Future<void> _reloadCarry() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null) return;
    final routineId = _routineId;
    final progress = routineId == null
        ? await _repo.getExerciseProgress(exerciseId)
        : await _repo.getRoutineProgress(routineId);
    _carry = progress.durationFor(
      exerciseId: exerciseId,
      routineEntryId: _routineEntryId,
    );
    final recordId = _record?.id;
    final stored = progress.records.where((r) => r.id == recordId).firstOrNull;
    if (stored != null) _carry -= stored.duration;
  }

  Future<void> _handleGap(
    PracticeRecord record,
    DateTime lastCheckpoint,
  ) async {
    final now = DateTime.now();
    final gap = now.difference(lastCheckpoint);
    final counted = _carry + record.duration;
    if (!_needsRecovery(gap, counted)) {
      await _checkpoint();
      _state = PracticeTimerState.running;
      _startTicker();
      return;
    }
    _recovery = PracticeRecovery(
      counted: counted,
      leftAt: lastCheckpoint,
      gap: gap,
    );
  }

  bool _needsRecovery(Duration gap, Duration counted) {
    final target = _target;
    if (target == null || target == Duration.zero) {
      return gap > minGapWithoutTarget;
    }
    if (gap <= minGapWithTarget) return false;
    return (counted + gap) > target * targetOvershoot;
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _detached = true;
        if (running) unawaited(_checkpoint(publish: true));
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (running) unawaited(_checkpoint(publish: true));
      case AppLifecycleState.resumed:
        _detached = false;
        if (running) unawaited(_onForeground());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onForeground() async {
    final record = _record;
    final runningSince = record?.runningSince;
    if (record == null || runningSince == null) return;
    final gap = DateTime.now().difference(runningSince);
    if (gap < checkpointInterval) return;
    if (!_needsRecovery(gap, _carry + record.duration)) {
      await _checkpoint();
      return;
    }
    _stopTicker();
    await _handleGap(record, runningSince);
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    _lifecycle.dispose();
    _ticks.dispose();
    super.dispose();
  }
}
