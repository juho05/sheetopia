/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_statistics.dart';

typedef ExerciseStatistic = ({String? name, Duration duration});

class PracticeStatisticsViewModel extends ChangeNotifier {
  static const int topExerciseCount = 5;

  final PracticeRepository _repo;
  final DateTime Function() _clock;

  int _firstWeekday = DateTime.monday;

  late StatisticsPeriod _period = StatisticsPeriod.containing(
    StatisticsTimeFrame.week,
    _clock(),
    firstWeekday: _firstWeekday,
  );

  StatisticsPeriod get period => _period;

  StatisticsTimeFrame get timeFrame => _period.frame;

  StatisticsResolution _resolution = StatisticsTimeFrame.week.resolutions.first;

  StatisticsResolution get resolution => _resolution;

  bool _loading = true;

  bool get loading => _loading;

  List<StatisticsBucket> _buckets = const [];

  UnmodifiableListView<StatisticsBucket> get buckets =>
      UnmodifiableListView(_buckets);

  int? _selectedBucket;

  int? get selectedBucket => _selectedBucket;

  Duration _total = Duration.zero;

  Duration get total => _total;

  Duration _dailyAverage = Duration.zero;

  Duration get dailyAverage => _dailyAverage;

  int _daysPracticed = 0;

  int get daysPracticed => _daysPracticed;

  int _elapsedDays = 1;

  int get elapsedDays => _elapsedDays;

  int _currentStreak = 0;

  int get currentStreak => _currentStreak;

  int _longestStreak = 0;

  int get longestStreak => _longestStreak;

  List<Duration> _weekdays = List.filled(7, Duration.zero);

  /// Starts at [firstWeekday].
  UnmodifiableListView<Duration> get weekdays =>
      UnmodifiableListView(_weekdays);

  List<Duration> _hours = List.filled(24, Duration.zero);

  UnmodifiableListView<Duration> get hours => UnmodifiableListView(_hours);

  List<ExerciseStatistic> _topExercises = const [];

  UnmodifiableListView<ExerciseStatistic> get topExercises =>
      UnmodifiableListView(_topExercises);

  final List<StreamSubscription> _subs = [];

  PracticeStatisticsViewModel({required this._repo, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _subs.addAll([
      _repo.updatedRecordIds.listen((_) => _load()),
      _repo.updatedExerciseIds.listen((_) => _load()),
    ]);
    _load();
  }

  int get firstWeekday => _firstWeekday;

  set firstWeekday(int value) {
    if (value == _firstWeekday) return;
    _firstWeekday = value;
    final now = _clock();
    _period = StatisticsPeriod.containing(
      _period.frame,
      _period.contains(now) ? now : _period.start,
      firstWeekday: value,
    );
    _selectedBucket = null;
    _load();
  }

  set timeFrame(StatisticsTimeFrame value) {
    if (value == _period.frame) return;
    final now = _clock();
    _period = StatisticsPeriod.containing(
      value,
      _period.contains(now) ? now : _period.lastDay,
      firstWeekday: _firstWeekday,
    );
    if (!value.resolutions.contains(_resolution)) {
      _resolution = value.resolutions.first;
    }
    _selectedBucket = null;
    notifyListeners();
    _load();
  }

  set resolution(StatisticsResolution value) {
    if (value == _resolution || !timeFrame.resolutions.contains(value)) return;
    _resolution = value;
    _selectedBucket = null;
    notifyListeners();
    _load();
  }

  set selectedBucket(int? value) {
    if (value == _selectedBucket) return;
    _selectedBucket = value;
    notifyListeners();
  }

  bool get hasNext => !_period.end.isAfter(_clock());

  bool get isCurrent =>
      _period.start ==
      StatisticsPeriod.containing(
        _period.frame,
        _clock(),
        firstWeekday: _firstWeekday,
      ).start;

  void previous() => _shift(-1);

  void next() {
    if (hasNext) _shift(1);
  }

  /// Shows the period containing [day], or the current one if that is later.
  void goTo(DateTime day) {
    final now = _clock();
    final period = StatisticsPeriod.containing(
      _period.frame,
      day.isAfter(now) ? now : day,
      firstWeekday: _firstWeekday,
    );
    if (period.start == _period.start) return;
    _period = period;
    _selectedBucket = null;
    notifyListeners();
    _load();
  }

  void goToToday() => goTo(_clock());

  DateTime get now => _clock();

  DateTime? _firstPracticed;

  DateTime? get firstPracticed => _firstPracticed;

  void _shift(int periods) {
    _period = _period.shifted(periods);
    _selectedBucket = null;
    notifyListeners();
    _load();
  }

  int _generation = 0;

  Future<void> _load() async {
    final generation = ++_generation;
    final now = _clock();
    final period = _period;
    final resolution = _resolution;
    final firstWeekday = _firstWeekday;
    final records = await _repo.getRecordsBetween(period.start, period.end);
    final startTimes = await _repo.getRecordStartTimes();
    final top = PracticeStatistics.byExercise(
      records,
      now: now,
    ).take(topExerciseCount).toList();
    final exercises = await _repo.getExercisesById({
      for (final t in top) t.exerciseId,
    });
    if (generation != _generation || _disposed) return;

    _buckets = PracticeStatistics.buckets(
      records,
      period,
      resolution,
      now: now,
      firstWeekday: firstWeekday,
    );
    _total = PracticeStatistics.total(records, now: now);
    _elapsedDays = period.elapsedDays(now);
    _dailyAverage = _total ~/ _elapsedDays;
    _daysPracticed = PracticeStatistics.daysPracticed(records);
    _firstPracticed = startTimes.isEmpty
        ? null
        : startTimes.reduce((a, b) => a.isBefore(b) ? a : b);
    final streaks = PracticeStatistics.streaks(startTimes, now: now);
    _currentStreak = streaks.current;
    _longestStreak = streaks.longest;
    _weekdays = PracticeStatistics.byWeekday(
      records,
      now: now,
      firstWeekday: firstWeekday,
    );
    _hours = PracticeStatistics.byHour(records, now: now);
    _topExercises = [
      for (final t in top)
        (name: exercises[t.exerciseId]?.name, duration: t.duration),
    ];
    final selected = _selectedBucket;
    if (selected != null &&
        (selected >= _buckets.length ||
            _buckets[selected].duration == Duration.zero)) {
      _selectedBucket = null;
    }
    _loading = false;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
