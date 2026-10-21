import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_driver/flutter_driver.dart';

import 'util.dart';

class _E2eCommand extends Command {
  final String action;
  final Map<String, Object?> args;

  const _E2eCommand(this.action, this.args, {super.timeout});

  @override
  String get kind => 'e2e';

  @override
  Map<String, String> serialize() => super.serialize()..addAll({'action': action, 'args': jsonEncode(args)});
}

/// One visible item of the `describe` action, see tool/test/app/main_e2e.dart.
class Item {
  final String type;
  final String? text;

  /// Code point of an icon button without tooltip, e.g. `0xf068`.
  final String? icon;
  final double x, y, width, height;

  Item(Map<String, Object?> json)
    : type = json['type'] as String,
      text = json['text'] as String?,
      icon = json['icon'] as String?,
      x = ((json['rect'] as List)[0] as num).toDouble(),
      y = ((json['rect'] as List)[1] as num).toDouble(),
      width = ((json['rect'] as List)[2] as num).toDouble(),
      height = ((json['rect'] as List)[3] as num).toDouble();

  List<double> get center => [x + width / 2, y + height / 2];

  @override
  String toString() => '$type ${jsonEncode(text)} [${[x, y, width, height].map((v) => v.round()).join(',')}]';
}

/// Operates the screenshot build (tool/screenshots/app/main_screenshots.dart)
/// through the E2E driver extension.
class AppDriver {
  final FlutterDriver _driver;
  final String url;

  AppDriver._(this._driver, this.url);

  static Future<AppDriver> connect(String url) async {
    driverLog = (source, message) {
      if (Platform.environment['SCREENSHOTS_VERBOSE'] == '1') stderr.writeln('$source: $message');
    };
    final driver = await FlutterDriver.connect(
      dartVmServiceUrl: url,
      printCommunication: false,
      logCommunicationToFile: false,
    ).timeout(const Duration(seconds: 60));
    return AppDriver._(driver, url);
  }

  Future<Map<String, Object?>> call(String action, [Map<String, Object?> args = const {}]) async {
    final response = await _driver.sendCommand(_E2eCommand(action, args, timeout: const Duration(seconds: 120)));
    final data = jsonDecode(response['data'] as String);
    return data is Map ? data.cast<String, Object?>() : {'data': data};
  }

  Future<void> close() => _driver.close();

  Future<List<Item>> describe() async {
    final result = await call('describe');
    return (result['items'] as List).cast<Map>().map((i) => Item(i.cast<String, Object?>())).toList();
  }

  Future<List<double>> size() async {
    final result = await call('describe');
    return (result['size'] as List).map((v) => (v as num).toDouble()).toList();
  }

  /// Visible items with exactly this text (or tooltip), top to bottom.
  Future<List<Item>> findAll({String? text, String? tooltip, bool contains = false}) async {
    final wanted = tooltip ?? text!;
    return (await describe()).where((i) {
      if (tooltip != null && i.type != 'tooltip') return false;
      if (text != null && i.type == 'tooltip') return false;
      final t = i.text ?? '';
      return contains ? t.contains(wanted) : t == wanted;
    }).toList();
  }

  Future<Item> find({String? text, String? tooltip, bool contains = false, int index = 0, int timeoutMs = 15000}) async {
    final sw = Stopwatch()..start();
    while (true) {
      final items = await findAll(text: text, tooltip: tooltip, contains: contains);
      if (index < items.length) return items[index];
      if (sw.elapsedMilliseconds > timeoutMs) {
        final visible = (await describe()).take(60).join('\n  ');
        throw ToolException('"${tooltip ?? text}" (${tooltip != null ? 'tooltip' : 'text'}, index $index) not on screen, '
            'found ${items.length}. Visible:\n  $visible');
      }
      await delay(250);
    }
  }

  Future<bool> visible({String? text, String? tooltip, bool contains = false}) async =>
      (await findAll(text: text, tooltip: tooltip, contains: contains)).isNotEmpty;

  Future<void> tapAt(List<double> at, {String kind = 'touch'}) async {
    await call('gesture', {
      'pointers': [
        {'kind': kind, 'points': [at]},
      ],
    });
  }

  Future<void> tap({String? text, String? tooltip, bool contains = false, int index = 0, String kind = 'touch'}) async {
    final item = await find(text: text, tooltip: tooltip, contains: contains, index: index);
    await tapAt(item.center, kind: kind);
    await settle();
  }

  Future<void> drag(List<List<double>> points, {int durationMs = 400}) async {
    await call('gesture', {
      'pointers': [
        {'kind': 'touch', 'points': points},
      ],
      'durationMs': durationMs,
    });
  }

  Future<void> type(String text, {bool replace = true, bool submit = false}) async {
    await call('type', {'text': text, 'replace': replace, 'submit': submit});
    await settle();
  }

  Future<void> unfocus() async {
    await call('unfocus');
    await settle();
  }

  Future<void> go(String location) async {
    await call('go', {'location': location});
    await settle();
  }

  Future<void> back() async {
    await call('back');
    await settle();
  }

  Future<void> theme(String mode) async {
    await call('theme', {'mode': mode});
    await settle();
  }

  Future<void> settle({int timeoutMs = 5000}) async {
    await call('settle', {'timeoutMs': timeoutMs});
  }

  Future<Map<String, Object?>> window(Map<String, Object?> args) => call('window', args);

  /// The app rendered by itself, without any window decoration or system UI.
  Future<Uint8List> renderPng(double pixelRatio) async {
    final result = await call('screenshot', {'pixelRatio': pixelRatio});
    return base64Decode(result['png'] as String);
  }

  Future<void> upload(String name, List<int> bytes) async {
    const chunk = 512 * 1024;
    for (var offset = 0; offset < bytes.length; offset += chunk) {
      final end = offset + chunk < bytes.length ? offset + chunk : bytes.length;
      await call('upload', {'name': name, 'data': base64Encode(bytes.sublist(offset, end)), 'append': offset > 0});
    }
  }
}
