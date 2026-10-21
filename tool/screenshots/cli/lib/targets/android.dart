import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../driver.dart';
import '../stage.dart';
import '../target.dart';
import '../util.dart';

class _Display {
  final int width, height, density;

  const _Display(this.width, this.height, this.density);
}

/// Google Play screenshots from a throwaway emulator (its AVD lives in the
/// run directory). One emulator serves every form factor, the display size
/// and density are overridden per form factor.
class AndroidTarget extends Target {
  @override
  String get id => 'android';

  // Play: sides between 320 and 3840 px, the long side at most twice the
  // short one. Phones today are taller than that, 18:9 is the closest.
  // Tablets keep their usual 16:10.
  static const _displays = {
    'android-phone': _Display(1080, 2160, 420),
    'android-tablet-7': _Display(1200, 1920, 320),
    'android-tablet-10': _Display(1600, 2560, 320),
  };

  @override
  List<FormFactor> get formFactors => const [
    FormFactor('android-phone', 'Google Play phone', 1080, 2160),
    FormFactor('android-tablet-7', 'Google Play 7" tablet', 1200, 1920),
    FormFactor('android-tablet-10', 'Google Play 10" tablet', 1600, 2560),
  ];

  static const _avd = 'sheetopia-screenshots';

  late final String _sdk = _findSdk();
  String? _image;
  String? _avdHome;
  String? _serial;
  Background? _emulator;
  Background? _flutter;
  AppDriver? _driver;

  static String _findSdk() {
    final env = Platform.environment;
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '';
    return env['ANDROID_SDK_ROOT'] ??
        env['ANDROID_HOME'] ??
        (Platform.isMacOS
            ? p.join(home, 'Library', 'Android', 'sdk')
            : Platform.isWindows
            ? p.join(env['LOCALAPPDATA'] ?? '', 'Android', 'Sdk')
            : p.join(home, 'Android', 'Sdk'));
  }

  String _tool(String dir, String name) => p.join(_sdk, dir, Platform.isWindows ? '$name${name == 'avdmanager' ? '.bat' : '.exe'}' : name);

  String get _adb => _tool('platform-tools', 'adb');

  Future<String> _shell(String command) => run(_adb, ['-s', _serial!, 'shell', command]);

  @override
  Future<String?> unavailableReason() async {
    if (!Directory(_sdk).existsSync()) return 'no Android SDK at $_sdk (set ANDROID_SDK_ROOT)';
    for (final (dir, name) in [('platform-tools', 'adb'), ('emulator', 'emulator'), ('cmdline-tools/latest/bin', 'avdmanager')]) {
      if (!File(_tool(dir, name)).existsSync()) return 'the SDK has no $name';
    }
    _image = _findImage();
    if (_image == null) return 'no system image for this CPU in ${p.join(_sdk, 'system-images')}';
    return null;
  }

  /// The newest installed image for the host's CPU. Play Store images don't
  /// allow adb root, which sets the time zone, so they come last.
  String? _findImage() {
    final abi = Platform.version.contains('arm64') ? 'arm64-v8a' : 'x86_64';
    const tags = ['google_apis', 'default', 'google_apis_playstore'];
    final candidates = <(int, int, int, String)>[];
    final root = Directory(p.join(_sdk, 'system-images'));
    if (!root.existsSync()) return null;
    for (final api in root.listSync().whereType<Directory>()) {
      final level = int.tryParse(p.basename(api.path).replaceFirst('android-', ''));
      if (level == null) continue;
      for (final (rank, tag) in tags.indexed) {
        if (File(p.join(api.path, tag, abi, 'build.prop')).existsSync()) {
          candidates.add((tag == 'google_apis_playstore' ? 1 : 0, level, rank, 'system-images;android-$level;$tag;$abi'));
        }
      }
    }
    candidates.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 != b.$2 ? b.$2 - a.$2 : a.$3 - b.$3);
    return candidates.firstOrNull?.$4;
  }

  String get _platform => _image!.endsWith('arm64-v8a') ? 'android-arm64' : 'android-x64';

  String _apk(Stage stage) => p.join(stage.dir, 'build', 'app', 'outputs', 'flutter-apk', 'app-profile.apk');

  @override
  Future<void> build(Stage stage, String logDir) async {
    log('flutter build apk --profile');
    await run(
      'flutter',
      ['build', 'apk', '--profile', '--target-platform', _platform, '-t', entryPoint, ...flutterDefines],
      workingDirectory: stage.dir,
      logFile: p.join(logDir, 'build-android.log'),
    );
  }

  /// A fresh install per form factor: opening scores reorders the library.
  @override
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir) async {
    if (_serial == null) await _boot(logDir);
    await _stopApp();
    await run(_adb, ['-s', _serial!, 'uninstall', _appId], check: false);
    // Grants the runtime permissions (Bluetooth for MIDI, notifications) so
    // no prompt covers the screenshots. flutter run reinstalls with -r, which
    // keeps them.
    await run(_adb, ['-s', _serial!, 'install', '-g', _apk(stage)]);
    await _setDisplay(_displays[formFactor.id]!);
    log('installing and starting the app on $_serial');
    _flutter = await Background.start(
      'flutter',
      ['run', '--profile', '-d', _serial!, '--use-application-binary', _apk(stage)],
      workingDirectory: stage.dir,
      logFile: p.join(logDir, 'android-flutter-run.log'),
    );
    final url = (await _flutter!.waitFor(vmServicePattern, timeout: const Duration(minutes: 5), what: 'flutter run')).group(1)!;
    await _demoMode();
    return _driver = await AppDriver.connect(url);
  }

  static const _appId = 'de.julianh.sheetopia';

  Future<void> _stopApp() async {
    await _driver?.close().catchError((_) {});
    _driver = null;
    _flutter?.write('q');
    await _flutter?.stop();
    _flutter = null;
  }

  Future<void> _boot(String logDir) async {
    _avdHome = p.join(p.dirname(logDir), 'android-avd');
    Directory(_avdHome!).createSync(recursive: true);
    final env = {'ANDROID_AVD_HOME': _avdHome!, 'ANDROID_SDK_ROOT': _sdk, 'ANDROID_HOME': _sdk};
    log('creating the emulator ($_image)');
    final create = await Process.start(
      _tool('cmdline-tools/latest/bin', 'avdmanager'),
      ['-s', 'create', 'avd', '-n', _avd, '-k', _image!, '-d', 'pixel_7', '--force'],
      environment: env,
    );
    create.stdin.writeln('no');
    await create.stdin.close();
    create.stdout.drain<void>();
    final createErr = StringBuffer();
    await create.stderr.transform(systemEncoding.decoder).forEach(createErr.write);
    if (await create.exitCode != 0) throw ToolException('avdmanager failed: $createErr');
    final config = File(p.join(_avdHome!, '$_avd.avd', 'config.ini'));
    config.writeAsStringSync(
      '${config.readAsLinesSync().where((l) => !l.startsWith('hw.ramSize=') && !l.startsWith('disk.dataPartition.size=')).join('\n')}\n'
      'hw.ramSize=4096\ndisk.dataPartition.size=6G\n',
    );

    final devices = await run(_adb, ['devices']);
    var port = 5590;
    while (devices.contains('emulator-$port')) {
      port += 2;
    }
    _serial = 'emulator-$port';
    _emulator = await Background.start(
      _tool('emulator', 'emulator'),
      ['-avd', _avd, '-port', '$port', '-no-window', '-no-audio', '-no-boot-anim', '-no-snapshot', '-wipe-data', '-gpu', 'swiftshader_indirect'],
      logFile: p.join(logDir, 'android-emulator.log'),
      environment: env,
    );
    log('booting $_serial');
    await run(_adb, ['-s', _serial!, 'wait-for-device']);
    for (var i = 0; (await run(_adb, ['-s', _serial!, 'shell', 'getprop', 'sys.boot_completed'], check: false)).trim() != '1'; i++) {
      if (i > 120) throw ToolException('the emulator did not boot, see ${_emulator!.logFile}');
      await delay(2000);
    }
    await run(_adb, ['-s', _serial!, 'root'], check: false);
    await run(_adb, ['-s', _serial!, 'wait-for-device']);
    // The demo library's practice history ends at the host's local time.
    final tz = await _hostTimeZone();
    if (tz != null && await _shell('id -u') != '0') {
      throw ToolException('adb root failed on $_image, the time zone can\'t be set. Install a google_apis image');
    }
    await _shell([
      if (tz != null) "setprop persist.sys.timezone '$tz'",
      'svc power stayon true',
      'input keyevent KEYCODE_WAKEUP',
      'wm dismiss-keyguard',
      // The first full screen page would show how to leave full screen.
      'settings put secure immersive_mode_confirmations confirmed',
    ].join('; '));
  }

  /// A clean status bar: 9:41, full battery and Wi-Fi, no notifications.
  Future<void> _demoMode() async {
    const demo = 'am broadcast -p com.android.systemui -a com.android.systemui.demo -e command';
    await _shell([
      // Set right after boot, it doesn't stick.
      'settings put global sysui_demo_allowed 1',
      '$demo enter',
      '$demo clock -e hhmm 0941',
      '$demo battery -e level 100 -e plugged false',
      '$demo network -e wifi show -e level 4 -e fully true',
      '$demo network -e mobile hide',
      '$demo notifications -e visible false',
    ].join('; '));
  }

  Future<String?> _hostTimeZone() async {
    if (Platform.isWindows) return null;
    final link = File('/etc/localtime');
    if (link.existsSync()) {
      final target = link.resolveSymbolicLinksSync();
      final i = target.indexOf('zoneinfo/');
      if (i >= 0) return target.substring(i + 'zoneinfo/'.length);
    }
    return null;
  }

  Future<void> _setDisplay(_Display display) async {
    await _shell('wm size ${display.width}x${display.height}; wm density ${display.density}');
    await delay(2000);
  }

  @override
  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor) async =>
      Uint8List.fromList(await runBytes(_adb, ['-s', _serial!, 'exec-out', 'screencap', '-p']));

  @override
  Future<void> close() async {
    await _stopApp();
    if (_serial != null) await run(_adb, ['-s', _serial!, 'emu', 'kill'], check: false);
    await _emulator?.stop(grace: const Duration(seconds: 30));
    if (_avdHome != null && Directory(_avdHome!).existsSync()) Directory(_avdHome!).deleteSync(recursive: true);
    _emulator = null;
    _serial = _avdHome = null;
  }
}
