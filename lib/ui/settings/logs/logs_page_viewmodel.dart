/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_message.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/settings/settings_repository.dart';
import 'package:sheetopia/utils/format.dart';

class LogsPageViewModel extends ChangeNotifier {
  final SettingsRepository _settings;
  final LogRepository _repository;

  StreamSubscription? _newMessageSubscription;

  DateTime _sessionTime;

  DateTime get sessionTime => _sessionTime;

  List<LogMessage> _logMessages;
  List<LogMessage> _filteredMessages;

  List<LogMessage> get logMessages => _filteredMessages;

  Set<Level> _enabledLevels;

  Set<Level> get enabledLevels => _enabledLevels;

  String _searchText;

  String get searchText => _searchText;

  LogsPageViewModel({
    required SettingsRepository settingsRepository,
    required LogRepository logRepository,
  }) : _settings = settingsRepository,
       _repository = logRepository,
       _sessionTime = Log.sessionStartTime,
       _logMessages = const [],
       _filteredMessages = const [],
       _enabledLevels = const {},
       _searchText = "" {
    _enabledLevels = [
      Level.trace,
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.fatal,
    ].where((l) => l >= _settings.logging.level).toSet();
    _loadMessages();
  }

  Future<void> enableMessageStream(bool loadNewMessages) async {
    if (sessionTime != Log.sessionStartTime) return;
    bool oldValue = _newMessageSubscription != null;
    if (oldValue == loadNewMessages) return;
    if (loadNewMessages) {
      await _loadMessages();
    } else {
      _newMessageSubscription?.cancel();
      _newMessageSubscription = null;
    }
  }

  Future<void> changeSessionTime(DateTime sessionTime) async {
    if (_sessionTime == sessionTime) return;
    _searchDebounce?.cancel();
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;
    _logMessages = [];
    _filteredMessages = [];
    _sessionTime = sessionTime;
    await _loadMessages();
  }

  set enabledLevels(Set<Level> levels) {
    _enabledLevels = levels;
    _updateFilteredLogMessages();
  }

  Timer? _searchDebounce;

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchText = query.toLowerCase();
      _updateFilteredLogMessages();
    });
  }

  Future<void> _loadMessages() async {
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;

    _logMessages = (await _repository.getMessages(sessionTime));

    if (sessionTime == Log.sessionStartTime) {
      _newMessageSubscription = _repository.newMessageStream.listen(
        _onNewMessage,
      );
    }

    _updateFilteredLogMessages();
  }

  void _onNewMessage(LogMessage msg) async {
    if (_logMessages.isEmpty) {
      _logMessages = [msg];
    } else {
      _logMessages.add(msg);
    }
    if (enabledLevels.contains(msg.level)) {
      _updateFilteredLogMessages();
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _searchText = "";
    _updateFilteredLogMessages();
  }

  Future<bool> shareLog({
    required bool filtered,
    Rect? sharePositionOrigin,
  }) async {
    final timeStr = DateFormat("yyyy-MM-dd_HH-mm-ss").format(sessionTime);
    final bytes = utf8.encode(_exportLog(filtered: filtered));
    final fileName = "sheetopia-logs_$timeStr.txt";

    final result = await SharePlus.instance.share(
      ShareParams(
        title: "Share logs",
        downloadFallbackEnabled: true,
        files: [XFile.fromData(bytes, mimeType: "text/plain", name: fileName)],
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      return false;
    }
    return true;
  }

  Future<bool> saveLog({required bool filtered}) async {
    final timeStr = DateFormat("yyyy-MM-dd_HH-mm-ss").format(sessionTime);
    final bytes = utf8.encode(_exportLog(filtered: filtered));

    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      final outputFile = await FilePicker.saveFile(
        fileName: "sheetopia-logs_$timeStr.txt",
        bytes: bytes,
        dialogTitle: "Export Sheetopia logs",
      );
      return outputFile != null;
    }
    final outputFile = await getSaveLocation(
      suggestedName: "sheetopia-logs_$timeStr.txt",
      confirmButtonText: "Save",
    );
    if (outputFile == null) {
      return false;
    }
    await File(outputFile.path).writeAsBytes(bytes);
    return true;
  }

  String _exportLog({required bool filtered}) {
    String logStr =
        "========================= Sheetopia Logs ${formatDateTime(sessionTime)} =========================\n";
    if (filtered) {
      logStr += _filteredMessages
          .map((msg) => msg.toString())
          .join("\n--------------------------------------------------\n");
    } else {
      logStr += _logMessages
          .map((msg) => msg.toString())
          .join("\n--------------------------------------------------\n");
    }
    return logStr;
  }

  void _updateFilteredLogMessages() {
    _filteredMessages = _logMessages
        .where(
          (m) =>
              enabledLevels.contains(m.level) &&
              (searchText.isEmpty ||
                  m.tag.toLowerCase().contains(searchText) ||
                  m.message.toLowerCase().contains(searchText)),
        )
        .toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _newMessageSubscription = null;
    super.dispose();
  }
}
