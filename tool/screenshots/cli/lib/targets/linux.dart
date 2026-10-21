import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../driver.dart';
import '../stage.dart';
import '../target.dart';
import '../util.dart';

/// The README screenshots: the app window with its KWin decoration, captured
/// by spectacle in a headless KWin at scale 2. KWin reads the user's kwinrc
/// and color scheme, so the title bar looks like on the desktop. The session
/// has its own D-Bus, which keeps the app away from the user's keyring and
/// KWin's D-Bus names away from the user's KWin.
class LinuxTarget extends Target {
  @override
  String get id => 'linux';

  @override
  List<FormFactor> get formFactors => const [
    // 1220x720 window content (the runner's default size) plus the 28px title
    // bar, at scale 2.
    FormFactor('linux', 'README, KDE window at scale 2', 2440, 1496, readme: true),
  ];

  static const _spectaclerc = '''
[General]
autoSaveImage=false
clipboardGroup=PostScreenshotDoNothing

[GuiConfig]
captureDelay=0
captureOnClick=false
includeDecorations=true
includePointer=false
includeShadow=false
transientOnly=false

[ImageSave]
preferredImageFormat=png
''';

  static const _outputWidth = 1600;
  static const _outputHeight = 1000;

  Background? _dbus;
  Background? _kwin;
  Background? _app;
  AppDriver? _driver;
  String? _dbusAddress;
  String? _socket;
  String? _home;

  @override
  Future<String?> unavailableReason() async {
    if (!Platform.isLinux) return 'needs a Linux host';
    for (final tool in ['kwin_wayland', 'kscreen-doctor', 'spectacle', 'dbus-daemon']) {
      if (!await which(tool)) return '$tool not installed';
    }
    return null;
  }

  @override
  Future<void> build(Stage stage, String logDir) async {
    log('flutter build linux --profile');
    await run(
      'flutter',
      ['build', 'linux', '--profile', '-t', entryPoint, ...flutterDefines],
      workingDirectory: stage.dir,
      logFile: p.join(logDir, 'build-linux.log'),
    );
  }

  Map<String, String> get _sessionEnvironment {
    final env = Map.of(Platform.environment)
      ..remove('DISPLAY')
      ..remove('WAYLAND_SOCKET');
    env['DBUS_SESSION_BUS_ADDRESS'] = _dbusAddress!;
    env['WAYLAND_DISPLAY'] = _socket!;
    return env;
  }

  @override
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir) async {
    _dbus = await Background.start(
      'dbus-daemon',
      ['--session', '--nofork', '--print-address=1'],
      logFile: p.join(logDir, 'linux-dbus.log'),
    );
    _dbusAddress = (await _dbus!.waitFor(RegExp(r'^(unix:\S+)$', multiLine: true), timeout: const Duration(seconds: 10), what: 'dbus-daemon')).group(1);

    _socket = 'sheetopia-screenshots-$pid';
    final kwinEnv = Map.of(Platform.environment)
      ..remove('DISPLAY')
      ..remove('WAYLAND_DISPLAY')
      ..['DBUS_SESSION_BUS_ADDRESS'] = _dbusAddress!;
    _kwin = await Background.start(
      'kwin_wayland',
      ['--virtual', '--width', '${_outputWidth * 2}', '--height', '${_outputHeight * 2}', '--socket', _socket!],
      logFile: p.join(logDir, 'linux-kwin.log'),
      environment: kwinEnv,
      includeParentEnvironment: false,
    );
    final runtime = Platform.environment['XDG_RUNTIME_DIR'] ?? '/run/user/${await run('id', ['-u'])}';
    for (var i = 0; !File(p.join(runtime, _socket!)).existsSync(); i++) {
      if (i > 100) throw ToolException('kwin_wayland did not create its socket, see ${_kwin!.logFile}');
      await delay(100);
    }
    // The virtual backend ignores --scale.
    final screenEnv = _sessionEnvironment..['QT_QPA_PLATFORM'] = 'wayland';
    final outputs = jsonDecode(await run('kscreen-doctor', ['--json'], environment: screenEnv))['outputs'] as List;
    final output = (outputs.first as Map)['name'] as String;
    await run('kscreen-doctor', ['output.$output.scale.2'], environment: screenEnv);

    // Fresh data, cache and temp directories. Config stays the user's so GTK
    // and fontconfig render like on the desktop, the app keeps nothing there.
    _home = p.join(p.dirname(logDir), 'linux-home');
    if (Directory(_home!).existsSync()) Directory(_home!).deleteSync(recursive: true);
    final env = _sessionEnvironment;
    for (final (name, dir) in [('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'), ('TMPDIR', 'tmp')]) {
      env[name] = p.join(_home!, dir);
      Directory(env[name]!).createSync(recursive: true);
    }
    env['GDK_BACKEND'] = 'wayland';
    _app = await Background.start(
      p.join(stage.dir, 'build', 'linux', 'x64', 'profile', 'bundle', 'sheetopia'),
      [],
      logFile: p.join(logDir, 'linux-app.log'),
      environment: env,
      includeParentEnvironment: false,
    );
    final url = (await _app!.waitFor(vmServicePattern, timeout: const Duration(seconds: 60), what: 'the app\'s VM service')).group(1)!;
    final driver = _driver = await AppDriver.connect(url);
    final window = await driver.window({});
    final size = (window['size'] as List).cast<num>();
    if (size[0] != 1220 || size[1] != 720) {
      log('warning: window is ${size.join('x')}, expected 1220x720, resizing');
      await driver.window({'width': 1220, 'height': 720});
    }
    return driver;
  }

  @override
  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor) async {
    final file = p.join(_home!, 'tmp', 'capture.png');
    if (File(file).existsSync()) File(file).deleteSync();
    // A config of its own, so the user's spectacle settings don't matter.
    final config = Directory(p.join(_home!, 'spectacle-config'))..createSync(recursive: true);
    File(p.join(config.path, 'spectaclerc')).writeAsStringSync(_spectaclerc);
    final env = _sessionEnvironment
      ..['QT_QPA_PLATFORM'] = 'wayland'
      ..['XDG_CONFIG_HOME'] = config.path;
    await run(
      'spectacle',
      ['--background', '--nonotify', '--activewindow', '--no-shadow', '--delay', '0', '--output', file],
      environment: env,
    );
    if (!File(file).existsSync()) throw ToolException('spectacle saved no screenshot, is the app window active?');
    return File(file).readAsBytesSync();
  }

  @override
  Future<void> close() async {
    await _driver?.close().catchError((_) {});
    _driver = null;
    await _app?.stop();
    await _kwin?.stop();
    await _dbus?.stop();
    _app = _kwin = _dbus = null;
    if (_home != null && Directory(_home!).existsSync()) Directory(_home!).deleteSync(recursive: true);
    _home = null;
  }
}
