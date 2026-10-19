// MCP server (stdio) for the E2E agents: operates one platform's screen
// through the environment scripts and answers every action with a downscaled
// screenshot, so seeing the effect costs no extra request.
//
//   tool.sh mcp --run <run dir> --platform linux|android|macos|ios
//   tool.sh mcp --path              prints the compiled executable's path
//
// Coordinates are pixels of the returned images (the server scales them to
// the device), except in the `drive` tool, which takes the driver's logical
// pixels. `batch` runs several actions with one screenshot at the end.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

typedef Json = Map<String, dynamic>;

late final String _run;
late final String _platform;
late final String _scripts;
late final Directory _tmp;

class _Tool {
  final String name;
  final String description;
  final Json properties;
  final List<String> required;
  final bool action;
  final Future<Object?> Function(Json args) run;

  _Tool(this.name, this.description, this.properties, this.run, {this.required = const [], this.action = true});

  Json get schema => {
    'name': name,
    'description': description,
    'inputSchema': {
      'type': 'object',
      'properties': {
        ...properties,
        if (action) ...{
          'look': {'type': 'boolean', 'description': 'return a screenshot afterwards (default true)'},
          'wait_ms': {'type': 'integer', 'description': 'wait before the screenshot (default 700)'},
          'save_as': {'type': 'string', 'description': 'also save the screenshot as evidence: screenshots/<platform>/<save_as>.png'},
        },
      },
      'required': required,
    },
  };
}

class _Screen {
  /// Image pixels per device pixel.
  final double scale;
  final Future<Uint8List> Function() capture;

  _Screen(this.scale, this.capture);
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('run')
    ..addOption('platform', allowed: ['linux', 'android', 'macos', 'ios'])
    ..addFlag('path', negatable: false);
  final a = parser.parse(arguments);
  if (a.flag('path')) {
    stdout.writeln(Platform.resolvedExecutable);
    return;
  }
  if (a.option('run') == null || a.option('platform') == null) {
    stderr.writeln('usage: mcp --run <run dir> --platform <platform>\n${parser.usage}');
    exit(64);
  }
  _run = p.absolute(a.option('run')!);
  _platform = a.option('platform')!;
  _scripts = p.join(p.dirname(p.dirname(_run)), 'scripts');
  _tmp = Directory.systemTemp.createTempSync('sheetopia-e2e-mcp-');

  final tools = {for (final t in _tools()) t.name: t};
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    final Json message;
    try {
      message = jsonDecode(line);
    } on FormatException {
      continue;
    }
    final id = message['id'];
    if (id == null) continue;
    try {
      final result = switch (message['method']) {
        'initialize' => {
          'protocolVersion': (message['params'] as Map?)?['protocolVersion'] ?? '2025-06-18',
          'capabilities': {'tools': <String, Object?>{}},
          'serverInfo': {'name': 'sheetopia-e2e', 'version': '1.0.0'},
        },
        'ping' => <String, Object?>{},
        'tools/list' => {'tools': [for (final t in tools.values) t.schema]},
        'tools/call' => await _call(tools, (message['params'] as Map).cast<String, dynamic>()),
        _ => throw _RpcError(-32601, 'unknown method ${message['method']}'),
      };
      _send({'jsonrpc': '2.0', 'id': id, 'result': result});
    } on _RpcError catch (e) {
      _send({'jsonrpc': '2.0', 'id': id, 'error': {'code': e.code, 'message': e.message}});
    }
  }
  _tmp.deleteSync(recursive: true);
}

class _RpcError {
  final int code;
  final String message;

  _RpcError(this.code, this.message);
}

void _send(Json message) => stdout.writeln(jsonEncode(message));

Future<Json> _call(Map<String, _Tool> tools, Json params) async {
  final tool = tools[params['name']] ?? (throw _RpcError(-32602, 'unknown tool ${params['name']}'));
  final Json args = (params['arguments'] as Map?)?.cast<String, dynamic>() ?? {};
  final content = <Json>[];
  try {
    final output = await tool.run(args);
    if (output is List<Json>) {
      content.addAll(output);
    } else if (output != null && output.toString().trim().isNotEmpty) {
      content.add({'type': 'text', 'text': output.toString().trim()});
    }
    if (tool.action && args['look'] != false) {
      final last = tool.name == 'batch' ? ((args['actions'] as List?)?.lastOrNull as Map?)?.cast<String, dynamic>() : null;
      await Future<void>.delayed(Duration(milliseconds: (args['wait_ms'] as num?)?.toInt() ?? 700));
      content.addAll(await _look(
        args['save_as'] as String?,
        sim: (args['sim'] ?? last?['sim']) as String?,
        driver: (last?['tool'] ?? tool.name) == 'drive',
      ));
    }
    return {'content': content};
  } on _ToolError catch (e) {
    return {
      'content': [...content, {'type': 'text', 'text': e.message}],
      'isError': true,
    };
  }
}

class _ToolError {
  final String message;

  _ToolError(this.message);
}

Future<String> _sh(String script, List<String> args) async {
  const timeout = Duration(minutes: 3);
  final process = await Process.start(p.join(_scripts, script), args);
  final out = process.stdout.transform(utf8.decoder).join();
  final err = process.stderr.transform(utf8.decoder).join();
  final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
    process.kill(ProcessSignal.sigkill);
    throw _ToolError('$script ${args.join(' ')} timed out after ${timeout.inMinutes} min');
  });
  if (exitCode != 0) throw _ToolError('$script ${args.join(' ')} failed (exit $exitCode): ${await err}${await out}'.trim());
  return out;
}

// --- Screens ------------------------------------------------------------------

String get _shot => p.join(_tmp.path, 'shot.png');

Future<Uint8List> _readShot() async => File(_shot).readAsBytes();

final _iosScales = <String, double>{};

Future<_Screen> _screen({String? sim, bool driver = false}) async {
  if (driver) {
    return _Screen(0.5, () async {
      await _drive(['screenshot', _shot]);
      return _readShot();
    });
  }
  switch (_platform) {
    case 'android':
      return _Screen(1 / 3, () async {
        await _sh('android.sh', ['screenshot', _run, _shot]);
        return _readShot();
      });
    case 'linux' || 'macos':
      return _Screen(0.5, () async {
        await _sh(_platform == 'linux' ? 'linux_env.sh' : 'macos_vm.sh', ['vnc', _run, 'screenshot', _shot]);
        return _readShot();
      });
    default:
      final s = sim ?? 'phone';
      Future<Uint8List> capture() async {
        await _sh('ios_sim.sh', ['screenshot', _run, '--sim', s, _shot]);
        return _readShot();
      }
      // Images in points, the unit axe uses.
      if (!_iosScales.containsKey(s)) {
        final width = img.decodePng(await capture())?.width;
        final points = await _iosPointsWidth(s);
        _iosScales[s] = width == null || points == null ? 1 / 3 : points / width;
      }
      return _Screen(_iosScales[s]!, capture);
  }
}

Future<double?> _iosPointsWidth(String sim) async {
  try {
    final Object? ui = jsonDecode(await _sh('ios_sim.sh', ['axe', _run, '--sim', sim, 'describe-ui']));
    final root = (ui is List ? ui.first : ui) as Map;
    return ((root['frame'] as Map)['width'] as num).toDouble();
  } catch (_) {
    return null;
  }
}

Future<List<Json>> _look(String? saveAs, {String? sim, bool driver = false}) async {
  final screen = await _screen(sim: sim, driver: driver);
  final full = img.decodePng(await screen.capture()) ?? (throw _ToolError('screenshot is not a PNG'));
  final image = screen.scale == 1 ? full : img.copyResize(full, width: (full.width * screen.scale).round(), interpolation: img.Interpolation.average);
  final png = img.encodePng(image, level: 6);
  final text = StringBuffer('screenshot ${image.width}x${image.height}');
  if (saveAs != null && saveAs.isNotEmpty) {
    final file = File(p.join(_run, 'screenshots', _platform, '${saveAs.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}.png'));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(png);
    text.write(', saved ${file.path}');
  }
  return [
    {'type': 'text', 'text': text.toString()},
    {'type': 'image', 'data': base64Encode(png), 'mimeType': 'image/png'},
  ];
}

/// Runs a long gesture and screenshots it [at] after its start, before it ends.
Future<List<Json>> _midLook(Future<String> gesture, Duration at, Json args) async {
  // A gesture failing before it is awaited below would crash the server.
  gesture.ignore();
  await Future<void>.delayed(at);
  final mid = await _look(args['save_as'] == null ? null : '${args['save_as']}-mid', sim: args['sim'] as String?);
  final output = await gesture;
  return [
    {'type': 'text', 'text': '$output\nduring the drag:'.trim()},
    ...mid,
    {'type': 'text', 'text': 'after the drop:'},
  ];
}

Future<double> _scaleOf(Json args) async => (await _screen(sim: args['sim'] as String?)).scale;

Future<String> _device(Json args, String key) async => ((args[key] as num) / await _scaleOf(args)).round().toString();

// --- Tools --------------------------------------------------------------------

Json _int(String description) => {'type': 'integer', 'description': description};

Json _str(String description) => {'type': 'string', 'description': description};

final _xy = {'x': _int('image x'), 'y': _int('image y')};
final _line = {'x1': _int('start x'), 'y1': _int('start y'), 'x2': _int('end x'), 'y2': _int('end y')};

List<_Tool> _tools() {
  final common = [
    _Tool('screenshot', 'Screenshot of the screen.', {if (_platform == 'ios') 'sim': _sim}, (_) async => null),
    _Tool(
      'zoom',
      'Native resolution crop of a screenshot region (x, y, width, height in image pixels) for reading small text. '
      'Coordinates of the zoomed image do not apply to other tools.',
      {..._xy, 'width': _int('image width'), 'height': _int('image height'), if (_platform == 'ios') 'sim': _sim},
      _zoom,
      required: ['x', 'y', 'width', 'height'],
      action: false,
    ),
  ];
  final tools = [
    ...common,
    ...switch (_platform) {
      'android' => _androidTools(),
      'ios' => _iosTools(),
      _ => _vncTools(),
    },
    if (_platform == 'linux') _driveTool(),
  ];
  return [...tools, _batchTool({for (final t in tools) if (t.action && t.name != 'screenshot') t.name: t})];
}

_Tool _batchTool(Map<String, _Tool> tools) => _Tool(
  'batch',
  'Several actions in one call, run in order, with one screenshot at the end. Each action is an object with "tool" '
  'and that tool\'s arguments, e.g. [{"tool": "click", "x": 300, "y": 40}, {"tool": "type", "text": "Bach"}, '
  '{"tool": "key", "keys": ["return"]}]. An action\'s wait_ms is the pause after it (default 300), its look and save_as '
  'are ignored: look, wait_ms and save_as of the batch apply to the final screenshot. Stops at the first failing action.',
  {
    'actions': {
      'type': 'array',
      'items': {
        'type': 'object',
        'properties': {'tool': {'type': 'string', 'enum': tools.keys.toList()}},
        'required': ['tool'],
      },
    },
  },
  (a) async {
    final actions = (a['actions'] as List).cast<Map>();
    final content = <Json>[];
    for (final (i, action) in actions.indexed) {
      final args = action.cast<String, dynamic>();
      final tool = tools[args['tool']];
      if (tool == null) throw _ToolError('action ${i + 1}: unknown tool ${args['tool']}');
      try {
        final output = await tool.run(args);
        if (output is List<Json>) {
          content.addAll(output);
        } else if (output != null && output.toString().trim().isNotEmpty) {
          content.add({'type': 'text', 'text': '${i + 1} ${tool.name}: ${output.toString().trim()}'});
        }
      } on _ToolError catch (e) {
        final done = content.where((c) => c['type'] == 'text').map((c) => c['text']).join('\n');
        throw _ToolError('${done.isEmpty ? '' : '$done\n'}action ${i + 1} (${tool.name}) failed, the rest did not run: ${e.message}');
      }
      if (i < actions.length - 1) await Future<void>.delayed(Duration(milliseconds: (args['wait_ms'] as num?)?.toInt() ?? 300));
    }
    return content;
  },
  required: ['actions'],
);

Future<List<Json>> _zoom(Json args) async {
  final screen = await _screen(sim: args['sim'] as String?);
  final full = img.decodePng(await screen.capture()) ?? (throw _ToolError('screenshot is not a PNG'));
  int d(String k) => ((args[k] as num) / screen.scale).round();
  var crop = img.copyCrop(full, x: d('x'), y: d('y'), width: d('width'), height: d('height'));
  if (crop.width > 1400 || crop.height > 1400) {
    crop = crop.width >= crop.height ? img.copyResize(crop, width: 1400) : img.copyResize(crop, height: 1400);
  }
  return [
    {'type': 'image', 'data': base64Encode(img.encodePng(crop, level: 6)), 'mimeType': 'image/png'},
  ];
}

List<_Tool> _androidTools() {
  Future<String> adb(List<String> args) => _sh('android.sh', [args.first, _run, ...args.skip(1)]);
  return [
    _Tool('tap', 'Tap (finger, or stylus).', {..._xy, 'stylus': {'type': 'boolean'}}, (a) async {
      final x = await _device(a, 'x'), y = await _device(a, 'y');
      return a['stylus'] == true ? adb(['stylus', 'tap', x, y]) : adb(['tap', x, y]);
    }, required: ['x', 'y']),
    _Tool('long_press', 'Long press.', {..._xy, 'ms': _int('duration, default 800')}, (a) async {
      final x = await _device(a, 'x'), y = await _device(a, 'y');
      return adb(['swipe', x, y, x, y, '${a['ms'] ?? 800}']);
    }, required: ['x', 'y']),
    _Tool('swipe', 'Swipe or drag (finger, or stylus).', {..._line, 'ms': _int('duration, default 300'), 'stylus': {'type': 'boolean'}}, (a) async {
      final c = [for (final k in ['x1', 'y1', 'x2', 'y2']) await _device(a, k)];
      return a['stylus'] == true ? adb(['stylus', 'swipe', ...c, '${a['ms'] ?? 400}']) : adb(['swipe', ...c, '${a['ms'] ?? 300}']);
    }, required: ['x1', 'y1', 'x2', 'y2']),
    _Tool(
      'drag',
      'Drag and drop (long press, move, release), e.g. a file from the Files app in split screen onto the app. '
      'look_mid also returns a screenshot taken while hovering over the target before the drop.',
      {..._line, 'ms': _int('duration, default 3000'), 'look_mid': {'type': 'boolean'}},
      (a) async {
        final ms = (a['ms'] as num?)?.toInt() ?? 3000;
        final run = adb(['adb', 'shell', 'input', 'draganddrop', for (final k in ['x1', 'y1', 'x2', 'y2']) await _device(a, k), '$ms']);
        return a['look_mid'] == true ? _midLook(run, Duration(milliseconds: ms * 85 ~/ 100), a) : run;
      },
      required: ['x1', 'y1', 'x2', 'y2'],
    ),
    _Tool('key', 'Key event, e.g. KEYCODE_BACK, KEYCODE_HOME, KEYCODE_APP_SWITCH, KEYCODE_ENTER.', {'key': _str('keycode')}, (a) => adb(['key', a['key'] as String]), required: ['key']),
    _Tool('type', 'Type text into the focused field.', {'text': _str('text')}, (a) => adb(['text', a['text'] as String]), required: ['text']),
    _Tool(
      'ui',
      'Accessibility tree as text: one line per visible element with its bounds [x1,y1,x2,y2] in image pixels. '
      'Cheaper than a screenshot for finding texts and buttons.',
      {},
      (a) async => _compactUi(await adb(['ui']), await _scaleOf(a)),
      action: false,
    ),
  ];
}

String _compactUi(String xml, double scale) {
  String decode(String s) => s.replaceAll('&quot;', '"').replaceAll('&apos;', "'").replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&#10;', ' ').replaceAll('&amp;', '&');
  final lines = <String>[];
  for (final node in RegExp(r'<node ([^>]*)>').allMatches(xml)) {
    final attrs = {for (final m in RegExp(r'([\w-]+)="([^"]*)"').allMatches(node.group(1)!)) m.group(1)!: decode(m.group(2)!)};
    final text = attrs['text'] ?? '', desc = attrs['content-desc'] ?? '';
    final flags = [
      for (final f in ['clickable', 'checked', 'selected', 'focused', 'scrollable'])
        if (attrs[f] == 'true') f,
      if (attrs['enabled'] == 'false') 'disabled',
    ];
    if (text.isEmpty && desc.isEmpty && !flags.contains('clickable') && !flags.contains('scrollable')) continue;
    final b = RegExp(r'\d+').allMatches(attrs['bounds'] ?? '').map((m) => (int.parse(m.group(0)!) * scale).round()).toList();
    lines.add('$b${text.isEmpty ? '' : ' "$text"'}${desc.isEmpty || desc == text ? '' : ' desc="$desc"'}${flags.isEmpty ? '' : ' ${flags.join(' ')}'}');
  }
  return lines.isEmpty ? '(no elements, is the screen off or the dump empty?)' : lines.join('\n');
}

List<_Tool> _vncTools() {
  final script = _platform == 'linux' ? 'linux_env.sh' : 'macos_vm.sh';
  Future<String> vnc(List<String> args) => _sh(script, ['vnc', _run, ...args]);
  final mods = _platform == 'macos' ? 'cmd, option, ctrl, shift' : 'ctrl, alt, shift, super';
  return [
    _Tool('click', 'Mouse click, optionally with modifiers held ($mods).', {
      ..._xy,
      'button': {'type': 'string', 'enum': ['left', 'right', 'middle']},
      'double': {'type': 'boolean'},
      'mod': _str('comma separated modifiers'),
    }, (a) async => vnc([
      'click', await _device(a, 'x'), await _device(a, 'y'),
      if (a['button'] != null) ...['--button', a['button'] as String],
      if (a['double'] == true) '--double',
      if (a['mod'] != null) ...['--mod', a['mod'] as String],
    ]), required: ['x', 'y']),
    _Tool('move', 'Move the mouse (hover).', _xy, (a) async => vnc(['move', await _device(a, 'x'), await _device(a, 'y')]), required: ['x', 'y']),
    _Tool(
      'drag',
      'Drag with the left button held, optionally with modifiers. look_mid also returns a screenshot taken while '
      'hovering over the target before the drop (drop scrims and hover states).',
      {..._line, 'mod': _str('comma separated modifiers'), 'look_mid': {'type': 'boolean'}},
      (a) async {
        final args = [
          'drag', for (final k in ['x1', 'y1', 'x2', 'y2']) await _device(a, k),
          if (a['mod'] != null) ...['--mod', a['mod'] as String],
        ];
        if (a['look_mid'] != true) return vnc(args);
        // Holds 1.5 s before moving and over the target, look in the second hold.
        return _midLook(vnc([...args, '--hold-ms', '1500']), const Duration(milliseconds: 2800), a);
      },
      required: ['x1', 'y1', 'x2', 'y2'],
    ),
    _Tool(
      'swipe',
      'Fast mouse fling with the left button, for swipe gestures. drag rests before releasing, which the app reads '
      'as a fling with no velocity.',
      _line,
      (a) async => vnc([
        'drag', for (final k in ['x1', 'y1', 'x2', 'y2']) await _device(a, k),
        '--steps', '8', '--hold-ms', '0',
      ]),
      required: ['x1', 'y1', 'x2', 'y2'],
    ),
    _Tool('scroll', 'Mouse wheel clicks at a point, positive dy scrolls down.', {..._xy, 'dy': _int('wheel clicks'), 'dx': _int('horizontal wheel clicks')}, (a) async => vnc([
      'scroll', await _device(a, 'x'), await _device(a, 'y'),
      '--dy', '${a['dy'] ?? 0}', '--dx', '${a['dx'] ?? 0}',
    ]), required: ['x', 'y']),
    _Tool('key', 'Key combos pressed one after another, e.g. ["ctrl+a", "return", "escape", "f11"].', {
      'keys': {'type': 'array', 'items': {'type': 'string'}},
    }, (a) => vnc(['key', ...(a['keys'] as List).cast<String>()]), required: ['keys']),
    _Tool('type', r'Type text (US keyboard characters, \n is Return).', {'text': _str('text')}, (a) => vnc(['type', a['text'] as String]), required: ['text']),
  ];
}

final _sim = {'type': 'string', 'enum': ['phone', 'tablet'], 'description': 'simulator, default phone'};

List<_Tool> _iosTools() {
  Future<String> axe(Json a, List<String> args) => _sh('ios_sim.sh', ['axe', _run, '--sim', (a['sim'] as String?) ?? 'phone', ...args]);
  Future<String> pt(Json a, String k) async => ((a[k] as num) / await _scaleOf(a)).toStringAsFixed(1);
  return [
    _Tool('tap', 'Tap.', {..._xy, 'sim': _sim}, (a) async => axe(a, ['tap', '-x', await pt(a, 'x'), '-y', await pt(a, 'y')]), required: ['x', 'y']),
    _Tool('long_press', 'Long press.', {..._xy, 'seconds': {'type': 'number', 'description': 'default 1'}, 'sim': _sim}, (a) async => axe(a, [
      'touch', '-x', await pt(a, 'x'), '-y', await pt(a, 'y'), '--down', '--up', '--delay', '${a['seconds'] ?? 1}',
    ]), required: ['x', 'y']),
    _Tool('swipe', 'Swipe or drag.', {..._line, 'sim': _sim}, (a) async => axe(a, [
      'swipe', '--start-x', await pt(a, 'x1'), '--start-y', await pt(a, 'y1'), '--end-x', await pt(a, 'x2'), '--end-y', await pt(a, 'y2'),
    ]), required: ['x1', 'y1', 'x2', 'y2']),
    _Tool('type', 'Type text into the focused field.', {'text': _str('text'), 'sim': _sim}, (a) => axe(a, ['type', a['text'] as String]), required: ['text']),
    _Tool('button', 'Hardware button: home, lock, side-button, siri, apple-pay.', {'name': _str('button'), 'sim': _sim}, (a) => axe(a, ['button', a['name'] as String]), required: ['name']),
    _Tool(
      'describe',
      'Accessibility tree with frames in points (iOS points = image pixels).',
      {'sim': _sim},
      (a) async {
        final out = await axe(a, ['describe-ui']);
        return out.length > 30000 ? '${out.substring(0, 30000)}\n(truncated)' : out;
      },
      action: false,
    ),
  ];
}

Future<String> _drive(List<String> args) async {
  final env = File(p.join(_run, 'env', 'linux.env'));
  final url = env.existsSync()
      ? env.readAsLinesSync().where((l) => l.startsWith('DRIVER_URL=')).map((l) => l.substring(11)).lastOrNull
      : null;
  if (url == null) throw _ToolError('the driver build is not running, start it with linux_env.sh driver');
  return _sh('tool.sh', ['drive', '--url', url, ...args]);
}

_Tool _driveTool() => _Tool(
  'drive',
  'One action of the E2E driver build (see the Linux guide), e.g. ["tap", "--text", "Import files"] or ["describe"]. '
  'Its coordinates are the app\'s logical pixels: describe rects are logical, the returned driver screenshot is half size, '
  'so multiply image coordinates by 2. Pass look=false for describe, route, wait and screenshot. '
  'Several drive actions in a row go into one `batch`.',
  {'args': {'type': 'array', 'items': {'type': 'string'}}},
  (a) => _drive((a['args'] as List).cast<String>()),
  required: ['args'],
);
