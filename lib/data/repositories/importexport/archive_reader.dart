/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

/// Keeps a zip file open on a worker isolate. Entry names are normalized
/// to relative posix paths, e.g. `./a\b` is found as `a/b`.
class ArchiveReader {
  final SendPort _commands;
  final ReceivePort _replies;
  final Map<int, Completer<Object?>> _pending = {};
  int _nextId = 0;
  bool _closed = false;

  ArchiveReader._(this._commands, this._replies);

  static Future<ArchiveReader> open(String zipPath) async {
    final replies = ReceivePort();
    final ready = Completer<SendPort>();
    ArchiveReader? reader;
    replies.listen((message) {
      if (reader != null) {
        reader._handle(message);
      } else if (message is SendPort) {
        ready.complete(message);
      } else if (!ready.isCompleted) {
        ready.completeError(StateError("archive worker failed: $message"));
      }
    });
    try {
      await Isolate.spawn(
        _worker,
        (replies.sendPort, zipPath),
        onError: replies.sendPort,
        onExit: replies.sendPort,
      );
      reader = ArchiveReader._(await ready.future, replies);
      return reader;
    } catch (_) {
      replies.close();
      rethrow;
    }
  }

  /// Runs [task] on the worker. It must be a static or top-level function.
  Future<R> run<R>(R Function(Archive archive) task) async {
    return await _request(task) as R;
  }

  /// Writes the entry [name] to [targetPath] by writing a .part file and renaming it into place.
  Future<void> extract(String name, String targetPath) async {
    await _request((name, targetPath));
  }

  Future<void> close() async {
    if (_closed) return;
    try {
      await _request(_close);
    } finally {
      _closed = true;
      _replies.close();
    }
  }

  Future<Object?> _request(Object request) {
    if (_closed) throw StateError("archive reader is closed");
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _commands.send((id, request));
    return completer.future;
  }

  void _handle(Object? message) {
    if (message is (int, Object?, Object?, String?)) {
      final (id, result, error, stackTrace) = message;
      final completer = _pending.remove(id);
      if (completer == null) return;
      if (error != null) {
        completer.completeError(error, StackTrace.fromString(stackTrace ?? ""));
      } else {
        completer.complete(result);
      }
      return;
    }

    final failure = StateError(
      message is List
          ? "archive worker failed: ${message.first}"
          : "archive worker exited",
    );
    for (final completer in _pending.values) {
      completer.completeError(failure);
    }
    _pending.clear();
    _closed = true;
    _replies.close();
  }

  static const _close = "close";

  static Future<void> _worker((SendPort, String) args) async {
    final (replies, zipPath) = args;
    final commands = ReceivePort();
    replies.send(commands.sendPort);

    InputFileStream? input;
    Archive? archive;
    Object? openError;
    StackTrace? openStackTrace;
    try {
      input = InputFileStream(zipPath);
      archive = _normalized(
        ZipDecoder().decodeStream(input, throwOnError: true),
      );
    } catch (e, st) {
      openError = e;
      openStackTrace = st;
    }

    int? closeId;
    await for (final message in commands) {
      final (int id, Object request) = message as (int, Object);
      if (request == _close) {
        closeId = id;
        break;
      }
      try {
        if (archive == null) {
          Error.throwWithStackTrace(openError!, openStackTrace!);
        }
        final Object? result;
        if (request case (String name, String targetPath)) {
          _extractEntry(archive, name, targetPath);
          result = null;
        } else {
          result = (request as Object? Function(Archive))(archive);
        }
        replies.send((id, result, null, null));
      } catch (e, st) {
        try {
          replies.send((id, null, e, st.toString()));
        } catch (_) {
          replies.send((id, null, Exception(e.toString()), st.toString()));
        }
      }
    }

    try {
      await archive?.clear();
      await input?.close();
    } finally {
      commands.close();
      if (closeId != null) replies.send((closeId, null, null, null));
    }
  }

  static Archive _normalized(Archive decoded) {
    final archive = Archive();
    for (final entry in decoded) {
      entry.name = _normalizeName(entry.name);
      archive.add(entry);
    }
    return archive;
  }

  static String _normalizeName(String name) => path.posix
      .normalize(name.replaceAll("\\", "/"))
      .replaceFirst(RegExp(r"^/+"), "");

  static void _extractEntry(Archive archive, String name, String targetPath) {
    final entry = archive.findFile(_normalizeName(name));
    if (entry == null || !entry.isFile) {
      throw PathNotFoundException(name, const OSError("not in archive"));
    }
    final part = File("$targetPath.part");
    try {
      final output = OutputFileStream(part.path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
      part.renameSync(targetPath);
    } catch (_) {
      if (part.existsSync()) part.deleteSync();
      rethrow;
    }
  }
}
