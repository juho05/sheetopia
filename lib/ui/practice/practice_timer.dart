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
import 'package:sheetopia/data/repositories/practice/practice_session.dart';
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

  PracticeSession? _session;

  String? _routineId;
  Duration _routineTarget = Duration.zero;

  /// Whether an exercise was practiced since the page was opened.
  bool _touched = false;

  String? _exerciseId;
  String? _routineEntryId;
  Duration? _target;

  PracticeSessionEntry? _entry;

  /// Time practiced for this exercise in this session outside of [_entry].
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

  PracticeSession? get session => _session;

  PracticeTimerState get state => _state;

  bool get running => _state == PracticeTimerState.running;

  bool get paused => _state == PracticeTimerState.paused;

  bool get started => _state != PracticeTimerState.idle;

  bool get ready => _exerciseId != null && !_resolving;

  PracticeRecovery? get recovery => _recovery;

  Duration? get target => _target;

  Duration get elapsed {
    final entry = _entry;
    if (entry == null) return _carry;
    if (_state == PracticeTimerState.idle) return _carry + entry.duration;
    return _carry + entry.elapsedAt(DateTime.now());
  }

  bool get overTarget {
    final target = _target;
    return target != null && target > Duration.zero && elapsed > target;
  }

  Future<void> openSession({
    String? routineId,
    Duration routineTarget = Duration.zero,
  }) async {
    if (_disposed) return;
    _routineId = routineId;
    _routineTarget = routineTarget;
    _session = await _repo.getCurrentSession(
      routineId: routineId,
      routineTarget: routineTarget,
    );
    _notify();
  }

  Future<void> show({
    required String exerciseId,
    String? routineEntryId,
    Duration? target,
  }) async {
    if (_disposed) return;
    final generation = ++_showGeneration;
    _stopTicker();
    _resolving = true;
    _state = PracticeTimerState.idle;
    _notify();
    await _stopEntry();
    _exerciseId = exerciseId;
    _routineEntryId = routineEntryId;
    _target = target;
    _entry = null;
    _recovery = null;
    _carry = Duration.zero;
    try {
      await _adoptRunningSession();
      if (_disposed) return;
      await _reloadCarry();
      if (_disposed) return;
      await _recoverRunningEntry();
    } finally {
      if (generation == _showGeneration) _resolving = false;
    }
    _notify();
  }

  /// Only one stopwatch runs at a time. One left running for this exercise
  /// brings its session along, one left running elsewhere is stopped at its
  /// last checkpoint.
  Future<void> _adoptRunningSession() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null || _disposed) return;
    final running = await _repo.getRunningSessionEntry();
    if (running == null || running.sessionId == _session?.id) return;
    if (running.matches(
      exerciseId: exerciseId,
      routineEntryId: _routineEntryId,
    )) {
      _session = await _repo.getSession(running.sessionId);
      return;
    }
    await _repo.checkpointSessionEntry(
      running,
      now: running.runningSince,
      stop: true,
    );
  }

  Future<void> start() async {
    final exerciseId = _exerciseId;
    if (exerciseId == null || running) return;
    final session = _session ??= await _repo.resumeOrStartSession(
      routineId: _routineId,
      routineTarget: _routineTarget,
    );
    _touched = true;
    final entry = await _repo.startSessionEntry(
      sessionId: session.id,
      exerciseId: exerciseId,
      routineEntryId: _routineEntryId,
    );
    _entry = entry;
    await _reloadCarry();
    _carry -= entry.duration;
    _state = PracticeTimerState.running;
    _startTicker();
    _notify();
  }

  Future<void> startNewSession() async {
    if (running || !ready) return;
    _session = await _repo.startNewSession(
      routineId: _routineId,
      routineTarget: _routineTarget,
    );
    _entry = null;
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
      if (_recovery == null) await _checkpoint();
      return;
    }
    await _stopEntry();
    final session = _session;
    if (session != null) await _repo.endSession(session.id);
  }

  Future<void> resolveRecovery(PracticeRecoveryChoice choice) async {
    final entry = _entry;
    final recovery = _recovery;
    if (entry == null || recovery == null) return;
    switch (choice) {
      case PracticeRecoveryChoice.discard:
        await _repo.discardSessionEntries(entry);
        _carry = Duration.zero;
        _entry = null;
        _state = PracticeTimerState.idle;
      case PracticeRecoveryChoice.untilLeft:
        _entry = await _repo.checkpointSessionEntry(
          entry,
          now: recovery.leftAt,
          stop: true,
        );
        _state = PracticeTimerState.idle;
      case PracticeRecoveryChoice.untilNow:
        _entry = await _repo.checkpointSessionEntry(entry);
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
    final runningSince = _entry?.runningSince;
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

  Future<void> _checkpoint({bool stop = false}) async {
    final entry = _entry;
    if (entry == null) return;
    final next = await _repo.checkpointSessionEntry(entry, stop: stop);
    if (next.id != entry.id) {
      // the stopwatch ran over midnight and continues in a new entry
      _entry = next;
      await _reloadCarry();
      _carry -= next.duration;
    } else {
      _entry = next;
    }
    _tick();
  }

  Future<void> _stopEntry() async {
    final entry = _entry;
    if (entry == null) return;
    _entry = await _repo.checkpointSessionEntry(
      entry,
      now: _recovery?.leftAt,
      stop: true,
    );
    _state = PracticeTimerState.idle;
  }

  Future<void> _reloadCarry() async {
    final session = _session;
    final exerciseId = _exerciseId;
    if (session == null || exerciseId == null) return;
    final reloaded = await _repo.getSession(session.id);
    if (reloaded == null) return;
    _session = reloaded;
    _carry = reloaded.durationFor(
      exerciseId: exerciseId,
      routineEntryId: _routineEntryId,
    );
  }

  Future<void> _recoverRunningEntry() async {
    final session = _session;
    final exerciseId = _exerciseId;
    if (session == null || exerciseId == null) return;
    for (final entry in session.entries) {
      final runningSince = entry.runningSince;
      if (runningSince == null) continue;
      if (!entry.matches(
        exerciseId: exerciseId,
        routineEntryId: _routineEntryId,
      )) {
        await _repo.checkpointSessionEntry(
          entry,
          now: runningSince,
          stop: true,
        );
        continue;
      }
      _entry = entry;
      _carry -= entry.duration;
      _touched = true;
      await _handleGap(entry, runningSince);
    }
  }

  Future<void> _handleGap(
    PracticeSessionEntry entry,
    DateTime lastCheckpoint,
  ) async {
    final now = DateTime.now();
    final gap = now.difference(lastCheckpoint);
    final counted = _carry + entry.duration;
    if (!_needsRecovery(gap, counted)) {
      _entry = await _repo.checkpointSessionEntry(entry, now: now);
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
        if (running) unawaited(_checkpoint());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (running) unawaited(_checkpoint());
      case AppLifecycleState.resumed:
        _detached = false;
        if (running) unawaited(_onForeground());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onForeground() async {
    final entry = _entry;
    final runningSince = entry?.runningSince;
    if (entry == null || runningSince == null) return;
    final gap = DateTime.now().difference(runningSince);
    if (gap < checkpointInterval) return;
    if (!_needsRecovery(gap, _carry + entry.duration)) {
      await _checkpoint();
      return;
    }
    _stopTicker();
    await _handleGap(entry, runningSince);
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
