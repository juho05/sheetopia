import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../driver.dart';
import '../stage.dart';
import '../target.dart';
import '../util.dart';

/// App Store screenshots from throwaway simulators, one per form factor.
/// Simulators only run debug builds, which look the same.
class IosTarget extends Target {
  @override
  String get id => 'ios';

  // App Store Connect: iPhone with Dynamic Island (medium display) 1206x2622,
  // iPhone Duo outer display 1398x2034, 13" iPad 2064x2752.
  @override
  List<FormFactor> get formFactors => const [
    FormFactor('ios-iphone-6.3', 'App Store iPhone 6.3"', 1206, 2622),
    FormFactor('ios-iphone-duo', 'App Store iPhone Duo', 1398, 2034),
    FormFactor('ios-ipad-13', 'App Store iPad 13"', 2064, 2752),
  ];

  // Newest first, any of them has the required resolution.
  static const _deviceTypes = {
    'ios-iphone-6.3': ['iPhone 18 Pro', 'iPhone 17 Pro', 'iPhone 17', 'iPhone 16 Pro'],
    'ios-iphone-duo': ['iPhone Duo'],
    'ios-ipad-13': ['iPad Pro 13-inch (M5)', 'iPad Pro 13-inch (M4)', 'iPad Air 13-inch (M3)', 'iPad Air 13-inch (M2)'],
  };

  String? _udid;
  String? _logDir;
  Background? _flutter;
  AppDriver? _driver;

  @override
  Future<String?> unavailableReason() async {
    if (!Platform.isMacOS) return 'needs a macOS host';
    final result = await Process.run('xcrun', ['simctl', 'help']);
    if (result.exitCode != 0) return 'xcrun simctl not available (Xcode missing?)';
    return null;
  }

  @override
  Future<void> build(Stage stage, String logDir) async {
    // flutter run builds for each simulator.
  }

  Future<Map<String, dynamic>> _simctl(List<String> args) async =>
      jsonDecode(await run('xcrun', ['simctl', 'list', ...args, '-j'])) as Map<String, dynamic>;

  @override
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir) async {
    _logDir = logDir;
    final runtimes = ((await _simctl(['runtimes']))['runtimes'] as List)
        .cast<Map>()
        .where((r) => r['platform'] == 'iOS' && r['isAvailable'] == true)
        .toList();
    if (runtimes.isEmpty) throw ToolException('no iOS simulator runtime installed');
    runtimes.sort((a, b) => _compareVersions(b['version'] as String, a['version'] as String));
    final allTypes = ((await _simctl(['devicetypes']))['devicetypes'] as List).cast<Map>();
    final candidates = _deviceTypes[formFactor.id]!
        .map((name) => allTypes.where((t) => t['name'] == name).firstOrNull)
        .nonNulls
        .toList();
    // Newest runtime that supports any candidate. Some runtimes only support
    // a single device (iOS 27.1 is iPhone Duo only), so this differs per form factor.
    Map? runtime;
    Map? type;
    for (final r in runtimes) {
      final supported = ((r['supportedDeviceTypes'] as List?) ?? const []).cast<Map>().map((t) => t['name'] as String).toSet();
      type = candidates.where((t) => supported.isEmpty || supported.contains(t['name'])).firstOrNull;
      if (type != null) {
        runtime = r;
        break;
      }
    }
    if (runtime == null || type == null) {
      final minRuntimes = candidates.map((t) => '${t['name']} needs iOS ${t['minRuntimeVersionString']}');
      throw ToolException('none of ${_deviceTypes[formFactor.id]!.join(', ')} available for '
          '${runtimes.map((r) => r['name']).join(', ')}'
          '${minRuntimes.isEmpty ? '' : ' (${minRuntimes.join(', ')}; install with `xcodebuild -downloadPlatform iOS`)'}');
    }

    log('creating a ${type['name']} simulator (${runtime['name']})');
    _udid = await run('xcrun', ['simctl', 'create', 'sheetopia-screenshots-${formFactor.id}', type['identifier'] as String, runtime['identifier'] as String]);
    await run('xcrun', ['simctl', 'boot', _udid!]);
    await run('xcrun', ['simctl', 'bootstatus', _udid!, '-b']);
    await run('xcrun', [
      'simctl', 'status_bar', _udid!, 'override',
      '--time', '9:41',
      '--dataNetwork', 'wifi', '--wifiMode', 'active', '--wifiBars', '3',
      '--cellularMode', 'active', '--cellularBars', '4', '--operatorName', '',
      '--batteryState', 'charged', '--batteryLevel', '100',
    ]);

    log('flutter run on ${type['name']} (builds and installs the app)');
    _flutter = await Background.start(
      'flutter',
      ['run', '--debug', '-d', _udid!, '-t', entryPoint, ...flutterDefines],
      workingDirectory: stage.dir,
      logFile: p.join(logDir, 'ios-flutter-run-${formFactor.id}.log'),
    );
    final url = (await _flutter!.waitFor(vmServicePattern, timeout: const Duration(minutes: 20), what: 'flutter run')).group(1)!;
    return _driver = await AppDriver.connect(url);
  }

  static int _compareVersions(String a, String b) {
    final x = a.split('.').map(int.parse).toList(), y = b.split('.').map(int.parse).toList();
    for (var i = 0; i < x.length || i < y.length; i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d;
    }
    return 0;
  }

  @override
  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor) async {
    final file = p.join(_logDir!, 'ios-capture.png');
    await run('xcrun', ['simctl', 'io', _udid!, 'screenshot', '--type=png', file]);
    final bytes = File(file).readAsBytesSync();
    File(file).deleteSync();
    return bytes;
  }

  @override
  Future<void> finish(FormFactor formFactor) => close();

  @override
  Future<void> close() async {
    await _driver?.close().catchError((_) {});
    _driver = null;
    _flutter?.write('q');
    await _flutter?.stop();
    _flutter = null;
    if (_udid != null) {
      await run('xcrun', ['simctl', 'shutdown', _udid!], check: false);
      await run('xcrun', ['simctl', 'delete', _udid!], check: false);
      _udid = null;
    }
  }
}
