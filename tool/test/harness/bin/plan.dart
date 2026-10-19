// Reads tool/test/test-plan.yaml (or `--plan <file>`) for scripts and the
// orchestrator.
//
//   dart run bin/plan.dart json                 whole plan as JSON
//   dart run bin/plan.dart get `dotted.path`    one value: scalars raw,
//                                               lists one item per line,
//                                               maps as JSON
//   dart run bin/plan.dart enabled `dotted.path` exit 0 if the value is true
//
// `--set path=value` (repeatable) overrides values, e.g.
// `--set phases.old_to_new_update.enabled=false`.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) {
  final args = [...arguments];
  var planPath = p.join(p.dirname(p.dirname(p.dirname(Platform.script.toFilePath()))), 'test-plan.yaml');
  final overrides = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--plan' && i + 1 < args.length) {
      planPath = args.removeAt(i + 1);
      args.removeAt(i--);
    } else if (args[i] == '--set' && i + 1 < args.length) {
      overrides.add(args.removeAt(i + 1));
      args.removeAt(i--);
    }
  }
  if (args.isEmpty) _usage();

  final Object? plan;
  try {
    plan = _plain(loadYaml(File(planPath).readAsStringSync()));
  } on Object catch (e) {
    stderr.writeln('failed to read $planPath: $e');
    exit(2);
  }
  for (final o in overrides) {
    final eq = o.indexOf('=');
    if (eq < 0) _usage();
    _set(plan, o.substring(0, eq).split('.'), _plain(loadYaml(o.substring(eq + 1))));
  }

  switch (args.first) {
    case 'json':
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan));
    case 'get' when args.length == 2:
      final value = _get(plan, args[1]);
      if (value is List) {
        for (final v in value) {
          stdout.writeln(v is String ? v : jsonEncode(v));
        }
      } else if (value is Map) {
        stdout.writeln(jsonEncode(value));
      } else if (value != null) {
        stdout.writeln(value);
      }
    case 'enabled' when args.length == 2:
      exit(_get(plan, args[1]) == true ? 0 : 1);
    default:
      _usage();
  }
}

Object? _get(Object? node, String path) {
  for (final key in path.split('.')) {
    if (node is Map && node.containsKey(key)) {
      node = node[key];
    } else if (node is List && int.tryParse(key) != null && int.parse(key) < node.length) {
      node = node[int.parse(key)];
    } else {
      return null;
    }
  }
  return node;
}

void _set(Object? node, List<String> path, Object? value) {
  for (final key in path.take(path.length - 1)) {
    if (node is! Map) throw ArgumentError('cannot set ${path.join('.')}');
    node = node.putIfAbsent(key, () => <String, Object?>{});
  }
  if (node is! Map) throw ArgumentError('cannot set ${path.join('.')}');
  node[path.last] = value;
}

Object? _plain(Object? yaml) => switch (yaml) {
  YamlMap() => {for (final e in yaml.entries) '${e.key}': _plain(e.value)},
  YamlList() => [for (final v in yaml) _plain(v)],
  _ => yaml,
};

Never _usage() {
  stderr.writeln('usage: plan.dart [--plan file] [--set path=value]... (json | get <path> | enabled <path>)');
  exit(64);
}
