// Serves the subset of GitHub the app's version check and updater use.
//
//   dart run bin/fake_github.dart --root <dir> [--port 8787] [--log <file>]
//
// Every subdirectory of `--root` is a release: its name is the tag (e.g.
// `v0.8.0`) and its files are the release assets. Repository files at a tag
// are read from `.contents/<tag>/<path>`. The directory is read on every
// request, so releases can be added or removed while the server runs.
//
// Endpoints (owner and repo are ignored):
//   GET /repos/<owner>/<repo>/tags                         tag list
//   GET /repos/<owner>/<repo>/contents/<path>?ref=<tag>    raw repository file
//   GET /<owner>/<repo>/releases/download/<tag>/<file>      release asset
//   GET /<owner>/<repo>/releases                           HTML listing
//   GET /_requests                                          logged requests
//
// Point the app at it with SHEETOPIA_GITHUB_API_URL and
// SHEETOPIA_GITHUB_WEB_URL (or the debug.sheetopia.* properties on Android),
// both set to the server's base URL.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('root', mandatory: true, help: 'directory with one subdirectory per release tag')
    ..addOption('host', defaultsTo: '0.0.0.0')
    ..addOption('port', defaultsTo: '8787')
    ..addOption('log', help: 'append one JSON line per request to this file')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(64);
  }
  if (args.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  final root = Directory(args.option('root')!).absolute;
  if (!root.existsSync()) {
    stderr.writeln('root ${root.path} does not exist');
    exit(66);
  }
  final logFile = args.option('log') == null ? null : File(args.option('log')!);
  final requests = <Map<String, Object?>>[];

  final server = await HttpServer.bind(args.option('host')!, int.parse(args.option('port')!));
  stdout.writeln('fake GitHub serving ${root.path} on http://${server.address.address}:${server.port}');

  await for (final request in server) {
    final entry = <String, Object?>{
      'time': DateTime.now().toIso8601String(),
      'method': request.method,
      'path': request.uri.path,
      'query': request.uri.query,
      'userAgent': request.headers.value(HttpHeaders.userAgentHeader),
      'remote': request.connectionInfo?.remoteAddress.address,
    };
    try {
      entry['status'] = await _handle(request, root, requests);
    } catch (e) {
      entry['status'] = 500;
      entry['error'] = e.toString();
      try {
        request.response.statusCode = 500;
        await request.response.close();
      } catch (_) {}
    }
    if (request.uri.path != '/_requests') {
      requests.add(entry);
      logFile?.writeAsStringSync('${jsonEncode(entry)}\n', mode: FileMode.append, flush: true);
      stdout.writeln('${entry['status']} ${request.method} ${request.uri}');
    }
  }
}

Future<int> _handle(HttpRequest request, Directory root, List<Map<String, Object?>> requests) async {
  final response = request.response;
  final segments = request.uri.pathSegments.where((s) => s.isNotEmpty).toList();

  if (request.method != 'GET' && request.method != 'HEAD') {
    return _send(response, 405, 'method not allowed');
  }

  if (segments.length == 1 && segments[0] == '_requests') {
    return _sendJson(response, requests);
  }

  // /repos/<owner>/<repo>/tags
  if (segments.length == 4 && segments[0] == 'repos' && segments[3] == 'tags') {
    final perPage = int.tryParse(request.uri.queryParameters['per_page'] ?? '') ?? 30;
    final page = int.tryParse(request.uri.queryParameters['page'] ?? '') ?? 1;
    final tags = _tags(root);
    final start = (page - 1) * perPage;
    final slice = start >= tags.length ? <String>[] : tags.sublist(start, (start + perPage).clamp(0, tags.length));
    return _sendJson(response, [
      for (final tag in slice) {'name': tag, 'commit': {'sha': '0' * 40, 'url': ''}},
    ]);
  }

  // /repos/<owner>/<repo>/contents/<path>?ref=<tag>
  if (segments.length >= 5 && segments[0] == 'repos' && segments[3] == 'contents') {
    final ref = request.uri.queryParameters['ref'] ?? '';
    final path = segments.sublist(4);
    if (ref.isEmpty || ref.contains('/') || ref.contains('..') || path.any((s) => s.contains('..') || s.contains('/'))) {
      return _send(response, 400, 'bad path');
    }
    final file = File(p.joinAll([root.path, '.contents', ref, ...path]));
    if (!file.existsSync()) return _send(response, 404, 'not found');
    response.headers.contentType = ContentType('application', 'vnd.github.raw+json', charset: 'utf-8');
    response.add(file.readAsBytesSync());
    await response.close();
    return 200;
  }

  // /<owner>/<repo>/releases/download/<tag>/<file>
  if (segments.length == 6 && segments[2] == 'releases' && segments[3] == 'download') {
    final tag = segments[4];
    final name = segments[5];
    if (tag.contains('..') || name.contains('..') || tag.contains('/') || name.contains('/')) {
      return _send(response, 400, 'bad path');
    }
    final file = File(p.join(root.path, tag, name));
    if (!file.existsSync()) return _send(response, 404, 'not found');
    final length = file.lengthSync();
    response.headers
      ..contentType = ContentType.binary
      ..contentLength = length
      ..set('content-disposition', 'attachment; filename="$name"');
    if (request.method == 'HEAD') {
      await response.close();
      return 200;
    }
    await response.addStream(file.openRead());
    await response.close();
    return 200;
  }

  // /<owner>/<repo>/releases
  if (segments.length == 3 && segments[2] == 'releases') {
    final buffer = StringBuffer('<!doctype html><title>Releases</title><h1>Fake releases</h1>');
    for (final tag in _tags(root)) {
      buffer.write('<h2>$tag</h2><ul>');
      for (final file in _assets(root, tag)) {
        final href = '/${segments[0]}/${segments[1]}/releases/download/$tag/${Uri.encodeComponent(file)}';
        buffer.write('<li><a href="$href">$file</a></li>');
      }
      buffer.write('</ul>');
    }
    response.headers.contentType = ContentType.html;
    response.write(buffer);
    await response.close();
    return 200;
  }

  return _send(response, 404, 'not found');
}

/// Tags newest first, like GitHub roughly does.
List<String> _tags(Directory root) {
  final tags = root.listSync().whereType<Directory>().map((d) => p.basename(d.path)).where((t) => !t.startsWith('.')).toList();
  tags.sort((a, b) => _compareVersions(b, a));
  return tags;
}

List<String> _assets(Directory root, String tag) =>
    Directory(p.join(root.path, tag)).listSync().whereType<File>().map((f) => p.basename(f.path)).toList()..sort();

int _compareVersions(String a, String b) {
  List<int> parts(String v) => v.replaceFirst(RegExp('^v'), '').split(RegExp(r'[.+-]')).map((s) => int.tryParse(s) ?? 0).toList();
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < pa.length || i < pb.length; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return a.compareTo(b);
}

Future<int> _send(HttpResponse response, int status, String body) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.text;
  response.write(body);
  await response.close();
  return status;
}

Future<int> _sendJson(HttpResponse response, Object? json) async {
  response.headers.contentType = ContentType.json;
  response.write(const JsonEncoder.withIndent('  ').convert(json));
  await response.close();
  return 200;
}
