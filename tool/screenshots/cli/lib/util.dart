import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

final String repoDir = _findRepo();

String _findRepo() {
  for (final start in [p.dirname(Platform.script.toFilePath()), Directory.current.path]) {
    var dir = p.absolute(start);
    while (true) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync() && RegExp(r'^name: sheetopia\s*$', multiLine: true).hasMatch(pubspec.readAsStringSync())) return dir;
      if (p.dirname(dir) == dir) break;
      dir = p.dirname(dir);
    }
  }
  throw ToolException('run this from inside the Sheetopia repository');
}

void log(String message) {
  final now = DateTime.now();
  final time = [now.hour, now.minute, now.second].map((v) => v.toString().padLeft(2, '0')).join(':');
  stderr.writeln('[$time] $message');
}

class ToolException implements Exception {
  final String message;

  ToolException(this.message);

  @override
  String toString() => message;
}

/// Runs a command to completion, throws with its output on failure.
Future<String> run(
  String executable,
  List<String> args, {
  String? workingDirectory,
  Map<String, String>? environment,
  String? logFile,
  bool check = true,
}) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final output = '${result.stdout}${result.stderr}';
  if (logFile != null) File(logFile).writeAsStringSync('\$ $executable ${args.join(' ')}\n$output', mode: FileMode.append);
  if (check && result.exitCode != 0) {
    final tail = LineSplitter.split(output).toList();
    throw ToolException(
      '$executable ${args.join(' ')} failed (${result.exitCode})'
      '${logFile != null ? ', see $logFile' : ''}\n${tail.skip(tail.length > 30 ? tail.length - 30 : 0).join('\n')}',
    );
  }
  return (result.stdout as String).trim();
}

Future<List<int>> runBytes(String executable, List<String> args) async {
  final process = await Process.start(executable, args);
  final bytes = <int>[];
  final err = StringBuffer();
  await Future.wait([
    process.stdout.forEach(bytes.addAll),
    process.stderr.transform(utf8.decoder).forEach(err.write),
  ]);
  final code = await process.exitCode;
  if (code != 0) throw ToolException('$executable ${args.join(' ')} failed ($code): $err');
  return bytes;
}

Future<bool> which(String executable) async {
  try {
    final result = await Process.run(Platform.isWindows ? 'where' : 'which', [executable]);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// A long running process whose output goes to a log file, e.g. `flutter run`
/// or the app itself. [waitFor] resolves with the first match of a pattern in
/// the output.
class Background {
  final Process process;
  final String logFile;
  final _output = StringBuffer();
  final _changed = StreamController<void>.broadcast();
  bool _exited = false;

  Background._(this.process, this.logFile) {
    final sink = File(logFile).openWrite(mode: FileMode.append);
    var closed = false;
    void add(String data) {
      if (!closed) sink.write(data);
      _output.write(data);
      _changed.add(null);
    }

    final out = process.stdout.transform(utf8.decoder).listen(add).asFuture<void>();
    final err = process.stderr.transform(utf8.decoder).listen(add).asFuture<void>();
    process.exitCode.then((code) async {
      _exited = true;
      // The exit code can arrive before the last output, and children of the
      // process may keep the pipes open.
      await Future.wait([out, err]).timeout(const Duration(seconds: 5), onTimeout: () => []);
      add('\n[exited with $code]\n');
      closed = true;
      await sink.close();
    });
  }

  static Future<Background> start(
    String executable,
    List<String> args, {
    required String logFile,
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
  }) async {
    File(logFile).parent.createSync(recursive: true);
    File(logFile).writeAsStringSync('\$ $executable ${args.join(' ')}\n', mode: FileMode.append);
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
    );
    return Background._(process, logFile);
  }

  Future<RegExpMatch> waitFor(RegExp pattern, {required Duration timeout, required String what}) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final match = pattern.firstMatch(_output.toString());
      if (match != null) return match;
      if (_exited) throw ToolException('$what: the process exited, see $logFile');
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) throw ToolException('$what: timed out after ${timeout.inSeconds}s, see $logFile');
      await _changed.stream.first.timeout(left, onTimeout: () {});
    }
  }

  void write(String input) {
    if (!_exited) process.stdin.write(input);
  }

  Future<void> stop({Duration grace = const Duration(seconds: 10)}) async {
    if (_exited) return;
    process.kill();
    await process.exitCode.timeout(grace, onTimeout: () {
      process.kill(ProcessSignal.sigkill);
      return -1;
    });
  }
}

Future<void> delay(int ms) => Future<void>.delayed(Duration(milliseconds: ms));
