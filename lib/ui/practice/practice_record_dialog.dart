/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sheetopia/data/repositories/practice/practice_progress.dart';
import 'package:sheetopia/ui/common/sheetopia_dialog.dart';
import 'package:sheetopia/ui/practice/select_exercise_dialog.dart';

typedef PracticeRecordInput = ({
  String exerciseId,
  DateTime startedAt,
  Duration duration,
});

class PracticeRecordDialog extends StatefulWidget {
  final String? exerciseId;
  final String? exerciseName;
  final DateTime? startedAt;
  final Duration? duration;

  const PracticeRecordDialog._({
    this.exerciseId,
    this.exerciseName,
    this.startedAt,
    this.duration,
  });

  bool get _editing => exerciseId != null;

  static Future<PracticeRecordInput?> create(BuildContext context) {
    return showSheetopiaDialog<PracticeRecordInput>(
      context: context,
      builder: (context) => const PracticeRecordDialog._(),
    );
  }

  static Future<PracticeRecordInput?> edit(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
    required DateTime startedAt,
    required Duration duration,
  }) {
    return showSheetopiaDialog<PracticeRecordInput>(
      context: context,
      builder: (context) => PracticeRecordDialog._(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        startedAt: startedAt,
        duration: duration,
      ),
    );
  }

  @override
  State<PracticeRecordDialog> createState() => _PracticeRecordDialogState();
}

class _PracticeRecordDialogState extends State<PracticeRecordDialog> {
  late String? _exerciseId = widget.exerciseId;
  late String? _exerciseName = widget.exerciseName;

  late DateTime _day;
  late TimeOfDay _time;

  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;

  @override
  void initState() {
    super.initState();
    final startedAt =
        widget.startedAt ??
        DateTime.now().subtract(widget.duration ?? Duration.zero);
    _day = PracticeProgress.startOfDay(startedAt);
    _time = TimeOfDay.fromDateTime(startedAt);
    final duration = widget.duration ?? Duration.zero;
    _minutesController = TextEditingController(
      text: widget._editing ? duration.inMinutes.toString() : "",
    );
    _secondsController = TextEditingController(
      text: widget._editing ? duration.inSeconds.remainder(60).toString() : "",
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  late bool _startPicked = widget._editing;

  // keeps the seconds of the original start so an unchanged time stays equal
  DateTime get _startedAt {
    if (!_startPicked) return DateTime.now().subtract(_duration);
    final original = widget.startedAt;
    final keepSeconds =
        original != null &&
        PracticeProgress.sameDay(original, _day) &&
        TimeOfDay.fromDateTime(original) == _time;
    return DateTime(
      _day.year,
      _day.month,
      _day.day,
      _time.hour,
      _time.minute,
      keepSeconds ? original.second : 0,
      keepSeconds ? original.millisecond : 0,
    );
  }

  Duration get _duration => Duration(
    minutes: int.tryParse(_minutesController.text) ?? 0,
    seconds: int.tryParse(_secondsController.text) ?? 0,
  );

  String? get _error {
    final duration = _duration;
    if (duration <= Duration.zero) return null;
    final startedAt = _startedAt;
    final now = DateTime.now();
    if (startedAt.isAfter(now)) {
      return "The start can't be in the future";
    }
    if (startedAt.add(duration).isAfter(now)) {
      return "The record can't end in the future";
    }
    final nextDay = PracticeProgress.startOfDay(
      PracticeProgress.startOfDay(
        startedAt,
      ).add(const Duration(days: 1, hours: 12)),
    );
    if (startedAt.add(duration).isAfter(nextDay)) {
      return "The record must end on the same day";
    }
    return null;
  }

  bool get _valid =>
      _exerciseId != null && _duration > Duration.zero && _error == null;

  void _submit() {
    final exerciseId = _exerciseId;
    if (!_valid || exerciseId == null) return;
    Navigator.pop(context, (
      exerciseId: exerciseId,
      startedAt: _startedAt,
      duration: _duration,
    ));
  }

  Future<void> _pickExercise() async {
    final exercise = await SelectExerciseDialog.show(context);
    if (exercise == null || !mounted) return;
    setState(() {
      _exerciseId = exercise.id;
      _exerciseName = exercise.name;
    });
  }

  void _pickStart() {
    if (_startPicked) return;
    final startedAt = _startedAt;
    _day = PracticeProgress.startOfDay(startedAt);
    _time = TimeOfDay.fromDateTime(startedAt);
    _startPicked = true;
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: PracticeProgress.startOfDay(_startedAt),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    setState(() {
      _pickStart();
      _day = day;
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _pickStart();
      _time = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final error = _error;
    final startedAt = _startedAt;
    return SheetopiaDialog(
      maxWidth: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            widget._editing ? "Edit record" : "Add record",
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
          if (widget._editing)
            Text(
              _exerciseName ?? "",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            )
          else
            OutlinedButton.icon(
              onPressed: _pickExercise,
              icon: const Icon(Symbols.exercise),
              label: Text(
                _exerciseName ?? "Select exercise",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDay,
                  icon: const Icon(Symbols.calendar_today),
                  label: Text(
                    localizations.formatMediumDate(startedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Symbols.schedule),
                  label: Text(
                    localizations.formatTimeOfDay(
                      TimeOfDay.fromDateTime(startedAt),
                      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(
                        context,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DurationField(
                  controller: _minutesController,
                  label: "Minutes",
                  autofocus: widget._editing,
                  onChanged: () => setState(() {}),
                  onSubmitted: _submit,
                ),
              ),
              Expanded(
                child: _DurationField(
                  controller: _secondsController,
                  label: "Seconds",
                  onChanged: () => setState(() {}),
                  onSubmitted: _submit,
                ),
              ),
            ],
          ),
          if (error != null)
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: _valid ? _submit : null,
                child: Text(widget._editing ? "Save" : "Add"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final void Function() onChanged;
  final void Function() onSubmitted;

  const _DurationField({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<_DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<_DurationField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.done,
      onChanged: (_) => widget.onChanged(),
      onSubmitted: (_) => widget.onSubmitted(),
      onTapOutside: (event) => _focus.unfocus(),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.label,
        hintText: "0",
      ),
    );
  }
}
