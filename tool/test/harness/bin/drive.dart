// Operates the E2E build of Sheetopia (tool/test/app/main_e2e.dart) through
// its driver extension. One invocation per action, prints JSON (describe:
// one compact line per item).
//
//   dart run bin/drive.dart [--url <vm service ws/http url>] <action> [...]
//
// The URL defaults to $SHEETOPIA_VM_SERVICE. Actions:
//
//   describe [--all] [--icons]     visible texts, tooltips, fields, switches
//                                  with rects [x, y, w, h] in logical px
//   tap (--text T | --tooltip T | --at X,Y) [--contains] [--index N]
//       [--kind touch|mouse|stylus] [--hold MS]
//                                  taps the center of a described item
//   draw --points "X,Y X,Y ..." [--kind stylus] [--duration MS] [--hold MS]
//                                  one stroke (also drags/swipes)
//   gesture '<json>'               raw multi-pointer gesture, see main_e2e.dart
//   scroll --at X,Y [--dx N] [--dy N] [--kind mouse|trackpad]
//   key <key> [--mod meta,shift,control,alt] [--hold down|up]
//   type <text> [--replace] [--submit]
//   drop <path>... [--at X,Y] [--cancel]
//   window [--size WxH] [--fullscreen true|false] [--maximize]
//   route                          current app route
//   back                           system back (Android back button/gesture)
//   settle [--timeout MS]          wait for animations to finish
//   wait (--text T | --tooltip T) [--gone] [--timeout MS]
//   screenshot <file.png> [--ratio R]

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_driver/flutter_driver.dart';

class E2eCommand extends Command {
  final String action;
  final Map<String, Object?> args;

  const E2eCommand(this.action, this.args, {super.timeout});

  @override
  String get kind => 'e2e';

  @override
  Map<String, String> serialize() =>
      super.serialize()..addAll({'action': action, 'args': jsonEncode(args)});
}

late FlutterDriver _driver;

Future<Object?> _call(String action, [Map<String, Object?> args = const {}]) async {
  final response = await _driver.sendCommand(E2eCommand(action, args, timeout: const Duration(seconds: 60)));
  return jsonDecode(response['data'] as String);
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('url', defaultsTo: Platform.environment['SHEETOPIA_VM_SERVICE'])
    ..addOption('text')
    ..addOption('tooltip')
    ..addOption('at')
    ..addOption('index', defaultsTo: '0')
    ..addOption('kind')
    ..addOption('hold')
    ..addOption('points')
    ..addOption('duration')
    ..addOption('dx')
    ..addOption('dy')
    ..addOption('mod')
    ..addOption('size')
    ..addOption('fullscreen')
    ..addOption('timeout')
    ..addOption('ratio')
    ..addFlag('contains', negatable: false)
    ..addFlag('all', negatable: false)
    ..addFlag('icons', negatable: false)
    ..addFlag('replace', negatable: false)
    ..addFlag('submit', negatable: false)
    ..addFlag('cancel', negatable: false)
    ..addFlag('maximize', negatable: false)
    ..addFlag('gone', negatable: false);

  final ArgResults a;
  try {
    a = parser.parse(arguments);
  } on FormatException catch (e) {
    _fail('${e.message}\n${parser.usage}');
  }
  if (a.rest.isEmpty) _fail('usage: drive <action> ... (see bin/drive.dart)');
  final url = a.option('url');
  if (url == null || url.isEmpty) _fail('no VM service URL, pass --url or set SHEETOPIA_VM_SERVICE');

  try {
    // The driver logs its connection progress, only show it when asked to.
    driverLog = (source, message) {
      if (Platform.environment['DRIVE_VERBOSE'] == '1') stderr.writeln('$source: $message');
    };
    _driver = await FlutterDriver.connect(
      dartVmServiceUrl: url,
      printCommunication: false,
      logCommunicationToFile: false,
    ).timeout(const Duration(seconds: 30));
  } catch (e) {
    _fail('could not connect to $url: $e');
  }

  final action = a.rest.first;
  final rest = a.rest.skip(1).toList();
  try {
    final result = await _run(action, rest, a);
    if (action == 'describe' && result is Map) {
      stdout.writeln('route: ${result['route']}  size: ${(result['size'] as List).map((v) => (v as num).round()).join('x')}  items: [x,y,w,h]');
      final items = (result['items'] as List).cast<Map>().map((i) => i.cast<String, Object?>()).toList();
      final tooltips = {for (final i in items) if (i['type'] == 'tooltip') '${i['text']}${i['rect']}'};
      for (final item in items) {
        if (item['type'] == 'text' && tooltips.contains('${item['text']}${item['rect']}')) continue;
        stdout.writeln(_describeLine(item));
      }
    } else {
      stdout.writeln(jsonEncode(result));
    }
  } catch (e) {
    stderr.writeln('error: $e');
    await _driver.close();
    exit(1);
  }
  await _driver.close();
  exit(0);
}

// e.g. `"Library" [20,100,41,16]`, `switch off disabled [..]`, `field "abc" focused [..]`.
String _describeLine(Map<String, Object?> item) {
  final type = item['type'];
  final rect = (item['rect'] as List).map((v) => (v as num).round()).join(',');
  return [
    if (type != 'text') type,
    if (item['text'] != null) jsonEncode(item['text']),
    if (item['icon'] != null) item['icon'],
    if (item['codePoint'] != null) item['codePoint'],
    if (item['value'] case final bool v) v ? 'on' : 'off',
    if (type == 'slider') '${item['value']} (${item['min']}-${item['max']})',
    if (item['focused'] == true) 'focused',
    if (item['obscured'] == true) 'obscured',
    if (item['enabled'] == false) 'disabled',
    if (item['covered'] == true) 'covered',
    '[$rect]',
  ].join(' ');
}

Future<Object?> _run(String action, List<String> rest, ArgResults a) async {
  switch (action) {
    case 'describe':
      return _call('describe', {'all': a.flag('all'), 'icons': a.flag('icons')});
    case 'route':
      return _call('route');
    case 'back':
      return _call('back');
    case 'settle':
      return _call('settle', {if (a.option('timeout') != null) 'timeoutMs': int.parse(a.option('timeout')!)});
    case 'screenshot':
      if (rest.isEmpty) _fail('screenshot needs a file path');
      final file = File(rest.first).absolute;
      final result = await _call('screenshot', {'pixelRatio': double.parse(a.option('ratio') ?? '1')}) as Map;
      file.writeAsBytesSync(base64Decode(result['png'] as String));
      return {'path': file.path};
    case 'tap':
      final at = await _target(a);
      return _call('gesture', {
        'pointers': [
          {'kind': a.option('kind') ?? 'touch', 'points': [at]},
        ],
        'holdMs': int.parse(a.option('hold') ?? '0'),
      }).then((_) => {'tapped': at});
    case 'draw':
      final points = (a.option('points') ?? '').trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).map(_point).toList();
      if (points.length < 2) _fail('draw needs at least two --points');
      return _call('gesture', {
        'pointers': [
          {'kind': a.option('kind') ?? 'stylus', 'points': points},
        ],
        'durationMs': int.parse(a.option('duration') ?? '400'),
        'holdMs': int.parse(a.option('hold') ?? '0'),
      });
    case 'gesture':
      if (rest.isEmpty) _fail('gesture needs a JSON argument');
      return _call('gesture', (jsonDecode(rest.first) as Map).cast<String, Object?>());
    case 'scroll':
      final at = _point(a.option('at') ?? _fail('scroll needs --at'));
      return _call('scroll', {
        'x': at[0],
        'y': at[1],
        'dx': double.parse(a.option('dx') ?? '0'),
        'dy': double.parse(a.option('dy') ?? '0'),
        'kind': a.option('kind') ?? 'mouse',
      });
    case 'key':
      return _call('key', {
        if (rest.isNotEmpty) 'key': rest.first,
        'modifiers': a.option('mod')?.split(',').where((m) => m.isNotEmpty).toList() ?? [],
        'hold': ?a.option('hold'),
      });
    case 'type':
      if (rest.isEmpty) _fail('type needs the text');
      return _call('type', {'text': rest.join(' '), 'replace': a.flag('replace'), 'submit': a.flag('submit')});
    case 'drop':
      if (rest.isEmpty && !a.flag('cancel')) _fail('drop needs file paths');
      final at = a.option('at') == null ? null : _point(a.option('at')!);
      return _call('drop', {'paths': rest, 'x': ?at?[0], 'y': ?at?[1], 'cancel': a.flag('cancel')});
    case 'window':
      if (rest.isNotEmpty) _fail('window takes no positional arguments, e.g. window --size 390x844');
      final sizeOption = a.option('size');
      if (sizeOption != null && !RegExp(r'^\d+(\.\d+)?x\d+(\.\d+)?$', caseSensitive: false).hasMatch(sizeOption)) {
        _fail('--size must be WIDTHxHEIGHT, e.g. --size 390x844');
      }
      final size = sizeOption?.toLowerCase().split('x').map(double.parse).toList();
      return _call('window', {
        'width': ?size?[0],
        'height': ?size?[1],
        if (a.option('fullscreen') != null) 'fullscreen': a.option('fullscreen') == 'true',
        'maximize': a.flag('maximize'),
      });
    case 'wait':
      final timeout = Duration(milliseconds: int.parse(a.option('timeout') ?? '15000'));
      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        final found = await _find(a, quiet: true);
        if (a.flag('gone') ? found == null : found != null) return {'found': !a.flag('gone'), 'ms': sw.elapsedMilliseconds};
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      throw StateError('timed out after ${timeout.inMilliseconds}ms waiting for ${a.option('text') ?? a.option('tooltip')}${a.flag('gone') ? ' to disappear' : ''}');
    default:
      _fail('unknown action $action');
  }
}

List<double> _point(String s) {
  final parts = s.split(',').map((p) => double.parse(p.trim())).toList();
  if (parts.length != 2) _fail('expected X,Y but got $s');
  return parts;
}

Future<List<double>> _target(ArgResults a) async {
  if (a.option('at') != null) return _point(a.option('at')!);
  final item = await _find(a);
  final rect = (item!['rect'] as List).cast<num>();
  return [rect[0] + rect[2] / 2, rect[1] + rect[3] / 2].map((v) => v.toDouble()).toList();
}

Future<Map?> _find(ArgResults a, {bool quiet = false}) async {
  final text = a.option('text'), tooltip = a.option('tooltip');
  if (text == null && tooltip == null) _fail('pass --text, --tooltip or --at');
  final described = await _call('describe') as Map;
  final items = (described['items'] as List).cast<Map>().where((i) {
    final wanted = tooltip ?? text!;
    if (tooltip != null && i['type'] != 'tooltip') return false;
    if (text != null && i['type'] == 'tooltip') return false;
    final t = i['text'] as String? ?? '';
    return a.flag('contains') ? t.toLowerCase().contains(wanted.toLowerCase()) : t == wanted;
  }).toList();
  final index = int.parse(a.option('index')!);
  if (index < items.length) return items[index];
  if (quiet) return null;
  throw StateError('found ${items.length} visible match(es) for ${tooltip != null ? 'tooltip' : 'text'} '
      '"${tooltip ?? text}", wanted index $index. Use describe to see what is on screen.');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
