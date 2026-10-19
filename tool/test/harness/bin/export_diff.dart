// Compares two Sheetopia archives (the app's export format) entity by entity.
//
//   dart run bin/export_diff.dart <expected.zip> <actual.zip>
//       [--ignore <pattern>]... [--json <report.json>]
//
// Entities are matched by `id` in every `*.json` file, score files by path
// and SHA-256. A pattern is `<file>.<field path>` with `*` matching any one
// segment, e.g. `scores.metadata.lastOpened` or `*.updatedAt`. List indices
// are segments too (`practice_routines.entries.*.id`).
//
// Exits 0 when the archives match, 1 when they differ, 2 on bad input.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addMultiOption('ignore', help: 'field pattern to ignore, repeatable')
    ..addOption('json', help: 'write the full report as JSON to this file');
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(2);
  }
  if (args.rest.length != 2) {
    stderr.writeln('usage: export_diff <expected.zip> <actual.zip> [options]\n\n${parser.usage}');
    exit(2);
  }

  final Map<String, ArchiveFile> expected, actual;
  try {
    expected = _read(args.rest[0]);
    actual = _read(args.rest[1]);
  } on Object catch (e) {
    stderr.writeln('failed to read archive: $e');
    exit(2);
  }

  final ignore = args.multiOption('ignore').map((p) => p.split('.')).toList();
  final differences = <Map<String, Object?>>[];
  final summary = <String, Map<String, int>>{};

  for (final marker in ['.sheetopia']) {
    if (!actual.containsKey(marker)) differences.add({'kind': 'missing-file', 'path': marker});
  }

  final jsonFiles = {...expected.keys, ...actual.keys}.where((n) => !n.contains('/') && n.endsWith('.json')).toList()..sort();
  for (final name in jsonFiles) {
    final entity = name.substring(0, name.length - '.json'.length);
    final e = expected[name], a = actual[name];
    if (e == null) {
      summary[entity] = {'expected': 0, 'actual': _decodeList(a!).length};
      continue; // Files only the newer app writes are fine.
    }
    if (a == null) {
      differences.add({'kind': 'missing-file', 'path': name});
      continue;
    }
    final eItems = _byId(_decodeList(e)), aItems = _byId(_decodeList(a));
    summary[entity] = {'expected': eItems.length, 'actual': aItems.length};
    for (final id in eItems.keys) {
      final aItem = aItems[id];
      if (aItem == null) {
        differences.add({'kind': 'missing', 'entity': entity, 'id': id, 'label': _label(eItems[id])});
        continue;
      }
      _compare(entity, id, [entity], eItems[id], aItem, ignore, differences);
    }
    for (final id in aItems.keys.where((id) => !eItems.containsKey(id))) {
      differences.add({'kind': 'unexpected', 'entity': entity, 'id': id, 'label': _label(aItems[id])});
    }
  }

  final eFiles = expected.keys.where((n) => n.startsWith('scores/')).toSet();
  final aFiles = actual.keys.where((n) => n.startsWith('scores/')).toSet();
  summary['score files'] = {'expected': eFiles.length, 'actual': aFiles.length};
  for (final path in eFiles) {
    if (!aFiles.contains(path)) {
      differences.add({'kind': 'missing-file', 'path': path});
    } else if (_sha(expected[path]!) != _sha(actual[path]!)) {
      differences.add({'kind': 'file-changed', 'path': path});
    }
  }
  for (final path in aFiles.difference(eFiles)) {
    differences.add({'kind': 'unexpected-file', 'path': path});
  }

  final report = {'match': differences.isEmpty, 'summary': summary, 'differences': differences};
  if (args.option('json') != null) {
    File(args.option('json')!).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  }

  summary.forEach((k, v) => stdout.writeln('$k: expected ${v['expected']}, actual ${v['actual']}'));
  if (differences.isEmpty) {
    stdout.writeln('MATCH');
    exit(0);
  }
  stdout.writeln('${differences.length} difference(s):');
  for (final d in differences.take(200)) {
    stdout.writeln('  ${jsonEncode(d)}');
  }
  if (differences.length > 200) stdout.writeln('  ... ${differences.length - 200} more (see --json)');
  exit(1);
}

Map<String, ArchiveFile> _read(String path) {
  final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
  return {for (final f in archive.files.where((f) => f.isFile)) f.name.replaceFirst(RegExp('^\\./'), ''): f};
}

List<dynamic> _decodeList(ArchiveFile file) {
  final decoded = jsonDecode(utf8.decode(file.content as List<int>));
  if (decoded is! List) throw FormatException('${file.name} is not a JSON list');
  return decoded;
}

Map<String, dynamic> _byId(List<dynamic> items) => {
  for (final (i, item) in items.indexed)
    (item is Map && item['id'] is String) ? item['id'] as String : '#$i': item,
};

String? _label(Object? item) {
  if (item is! Map) return null;
  for (final key in ['title', 'name']) {
    if (item[key] is String) return item[key] as String;
  }
  return null;
}

String _sha(ArchiveFile file) => sha256.convert(file.content as List<int>).toString();

bool _ignored(List<String> path, List<List<String>> patterns) {
  for (final pattern in patterns) {
    // `*.field` matches the field at any depth in any file.
    if (pattern.length == 2 && pattern[0] == '*' && path.last == pattern[1]) return true;
    if (pattern.length != path.length) continue;
    var ok = true;
    for (var i = 0; i < path.length && ok; i++) {
      ok = pattern[i] == '*' || pattern[i] == path[i];
    }
    if (ok) return true;
  }
  return false;
}

void _compare(
  String entity,
  String id,
  List<String> path,
  Object? expected,
  Object? actual,
  List<List<String>> ignore,
  List<Map<String, Object?>> out,
) {
  if (path.length > 1 && _ignored(path, ignore)) return;
  if (expected is Map && actual is Map) {
    for (final key in {...expected.keys, ...actual.keys}) {
      if (!expected.containsKey(key)) continue; // New fields written by a newer app are fine.
      _compare(entity, id, [...path, '$key'], expected[key], actual[key], ignore, out);
    }
    return;
  }
  if (expected is List && actual is List) {
    if (expected.length != actual.length) {
      out.add({'kind': 'changed', 'entity': entity, 'id': id, 'field': path.skip(1).join('.'), 'expected': '${expected.length} items', 'actual': '${actual.length} items'});
      return;
    }
    for (var i = 0; i < expected.length; i++) {
      _compare(entity, id, [...path, '$i'], expected[i], actual[i], ignore, out);
    }
    return;
  }
  if (expected != actual && !(expected is num && actual is num && expected == actual)) {
    out.add({'kind': 'changed', 'entity': entity, 'id': id, 'field': path.skip(1).join('.'), 'expected': _short(expected), 'actual': _short(actual)});
  }
}

Object? _short(Object? value) {
  final s = jsonEncode(value);
  return s.length > 200 ? '${s.substring(0, 200)}...' : value;
}
