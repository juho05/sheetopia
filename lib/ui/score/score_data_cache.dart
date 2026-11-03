/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/scores/stroke.dart';
import 'package:sheetopia/data/services/score_processing/page_margins.dart';
import 'package:sheetopia/ui/score/page_region.dart';

class _ScoreData {
  Map<int, List<Stroke>>? annotations;
  bool annotationsSettled = false;

  // A load still in flight must not replace newer strokes.
  int annotationsGeneration = 0;

  PageMargins? margins;
  bool marginsKnown = false;

  PageMargins? strokeInsets;
  bool strokesKnown = false;

  bool excluded = false;
  bool excludedKnown = false;
  int excludedGeneration = 0;

  bool get cropKnown =>
      excludedKnown && (excluded || (marginsKnown && strokesKnown));
}

/// The annotations and the crop of the scores a PDF view shows or is about to
/// show.
class ScoreDataCache extends ChangeNotifier {
  final ScoresRepository _scoresRepository;

  final Map<String, _ScoreData> _scores = {};

  StreamSubscription? _updatesSub;

  bool _disposed = false;

  bool _cropEnabled;
  double _cropPadding;

  bool get cropEnabled => _cropEnabled;

  // the crop of a shown score stays while annotating, so that erasing a stroke
  // in the margin does not move the page under the pen
  bool _annotating = false;

  ScoreDataCache({
    required this._scoresRepository,
    this._cropEnabled = false,
    this._cropPadding = 0,
  }) {
    _updatesSub = _scoresRepository.updatedScoreIds.listen((ids) {
      for (final MapEntry(key: id, value: score) in _scores.entries) {
        if (!ids.contains(id)) continue;
        _loadAnnotations(id, score);
        if (_cropEnabled) _loadExcluded(id, score);
      }
    });
  }

  set annotating(bool value) {
    if (value == _annotating) return;
    _annotating = value;
    if (value || !_cropEnabled) return;
    _scores.values.forEach(_updateStrokeInsets);
    notifyListeners();
  }

  void updateCrop({required bool enabled, required double padding}) {
    _cropPadding = padding;
    if (enabled == _cropEnabled) return;
    _cropEnabled = enabled;
    if (!enabled) return;
    for (final MapEntry(key: id, value: score) in _scores.entries) {
      score.strokesKnown = false;
      score.excludedKnown = false;
      _updateStrokeInsets(score);
      if (!score.marginsKnown) _loadMargins(id, score);
      _loadExcluded(id, score);
    }
  }

  // Without a prune the scores no longer wanted are kept as well.
  void track(Set<String> scoreIds, {required bool prune}) {
    if (prune) _scores.removeWhere((id, _) => !scoreIds.contains(id));
    for (final id in scoreIds) {
      if (_scores.containsKey(id)) continue;
      final score = _scores[id] = _ScoreData();
      _loadAnnotations(id, score);
      if (_cropEnabled) {
        _loadMargins(id, score);
        _loadExcluded(id, score);
      }
    }
  }

  Map<int, List<Stroke>>? annotationsOf(String? scoreId) =>
      _scores[scoreId]?.annotations;

  void setAnnotations(Map<String, Map<int, List<Stroke>>> annotations) {
    for (final MapEntry(key: scoreId, value: pages) in annotations.entries) {
      final score = _scores[scoreId];
      if (score == null) continue;
      score.annotationsGeneration++;
      score.annotations = pages;
      score.annotationsSettled = true;
      _updateStrokeInsets(score);
    }
    notifyListeners();
  }

  bool? excludedOf(String scoreId) {
    final score = _scores[scoreId];
    if (!_cropEnabled || score == null || !score.excludedKnown) return null;
    return score.excluded;
  }

  bool cropReady(String scoreId) =>
      !_cropEnabled || (_scores[scoreId]?.cropKnown ?? false);

  Rect visibleRegion(String? scoreId, Size pageSize) {
    final score = _scores[scoreId];
    final margins = score?.margins;
    if (!_cropEnabled || score == null || score.excluded || margins == null) {
      return fullPageRegion;
    }
    return visiblePageRegion(
      pageSize: pageSize,
      margins: margins,
      padding: _cropPadding,
      strokes: score.strokeInsets,
    );
  }

  /// For a score whose file may have changed since its margins were loaded.
  /// With [keepUntilLoaded] the old margins count as known meanwhile.
  Future<void> reloadMargins(
    String scoreId, {
    bool keepUntilLoaded = false,
  }) async {
    final score = _scores[scoreId];
    if (!_cropEnabled || score == null) return;
    if (keepUntilLoaded) {
      if (!score.marginsKnown) return;
    } else {
      score.marginsKnown = false;
    }
    await _loadMargins(scoreId, score);
  }

  void _updateStrokeInsets(_ScoreData score) {
    if (!_cropEnabled || !score.annotationsSettled) return;
    if (_annotating && score.strokesKnown) return;
    score.strokeInsets = strokeInsets(score.annotations ?? const {});
    score.strokesKnown = true;
  }

  Future<void> _loadAnnotations(String scoreId, _ScoreData score) async {
    final generation = ++score.annotationsGeneration;
    Map<int, List<Stroke>>? annotations;
    try {
      annotations = await _scoresRepository.getAnnotations(scoreId);
    } catch (e, st) {
      Log.error("Failed to load annotations of $scoreId", e: e, st: st);
    }
    if (_disposed ||
        !identical(_scores[scoreId], score) ||
        generation != score.annotationsGeneration) {
      return;
    }
    if (annotations != null) score.annotations = annotations;
    score.annotationsSettled = true;
    _updateStrokeInsets(score);
    notifyListeners();
  }

  Future<void> _loadMargins(String scoreId, _ScoreData score) async {
    PageMargins? margins;
    try {
      margins = await _scoresRepository.getPageMargins(scoreId);
    } catch (e, st) {
      Log.error("Failed to load page margins of $scoreId", e: e, st: st);
    }
    if (_disposed || !identical(_scores[scoreId], score)) return;
    score.margins = margins;
    score.marginsKnown = true;
    notifyListeners();
  }

  Future<void> _loadExcluded(String scoreId, _ScoreData score) async {
    final generation = ++score.excludedGeneration;
    var excluded = false;
    try {
      excluded = await _scoresRepository.getCropExcluded(scoreId);
    } catch (e, st) {
      Log.error("Failed to load crop exclusion of $scoreId", e: e, st: st);
    }
    if (_disposed ||
        !identical(_scores[scoreId], score) ||
        generation != score.excludedGeneration) {
      return;
    }
    final changed = !score.excludedKnown || excluded != score.excluded;
    score.excluded = excluded;
    score.excludedKnown = true;
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _updatesSub?.cancel();
    super.dispose();
  }
}
