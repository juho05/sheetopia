import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../driver.dart';
import '../images.dart';
import '../stage.dart';
import '../target.dart';
import '../util.dart';

/// Desktop stores: the app renders itself at an exact size, without the
/// window frame. The build has its own bundle id (see stage.dart) and its
/// data directories are deleted before and after.
abstract class _DesktopTarget extends Target {
  /// Logical window content sizes to try, the first that fits the screen
  /// wins and is rendered at the form factor's pixel width.
  List<(int, int)> get _layouts;

  List<String> get _dataDirs;

  Background? _flutter;
  AppDriver? _driver;
  double _ratio = 1;

  @override
  Future<void> build(Stage stage, String logDir) async {
    // flutter run builds.
  }

  void _clean() {
    for (final path in _dataDirs) {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.directory) Directory(path).deleteSync(recursive: true);
      if (type == FileSystemEntityType.file) File(path).deleteSync();
    }
  }

  @override
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir) async {
    _clean();
    log('flutter run --profile -d $id (builds the app)');
    _flutter = await Background.start(
      'flutter',
      ['run', '--profile', '-d', id, '-t', entryPoint, ...flutterDefines],
      workingDirectory: stage.dir,
      logFile: p.join(logDir, '$id-flutter-run.log'),
    );
    final url = (await _flutter!.waitFor(vmServicePattern, timeout: const Duration(minutes: 20), what: 'flutter run')).group(1)!;
    final driver = _driver = await AppDriver.connect(url);
    await driver.settle(timeoutMs: 15000);

    for (final (w, h) in _layouts) {
      // setSize may include the title bar, correct by what the app reports.
      var request = [w.toDouble(), h.toDouble()];
      for (var attempt = 0; attempt < 3; attempt++) {
        final result = await driver.window({'width': request[0], 'height': request[1]});
        final size = (result['size'] as List).map((v) => (v as num).toDouble()).toList();
        if ((size[0] - w).abs() < 0.5 && (size[1] - h).abs() < 0.5) {
          _ratio = formFactor.width / w;
          log('window content ${w}x$h, rendered at ${_ratio}x');
          return driver;
        }
        request = [request[0] + w - size[0], request[1] + h - size[1]];
      }
    }
    throw ToolException('could not size the window to any of ${_layouts.map((l) => '${l.$1}x${l.$2}').join(', ')}, is the screen too small?');
  }

  @override
  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor) => driver.renderPng(_ratio);

  @override
  Future<void> close() async {
    await _driver?.close().catchError((_) {});
    _driver = null;
    _flutter?.write('q');
    await _flutter?.stop();
    _flutter = null;
    _clean();
  }
}

class MacosTarget extends _DesktopTarget {
  String? _appDir;
  String? _logDir;

  @override
  String get id => 'macos';

  @override
  Future<AppDriver> start(Stage stage, FormFactor formFactor, String logDir) async {
    _appDir = p.join(stage.dir, 'build', 'macos');
    _logDir = logDir;
    return super.start(stage, formFactor, logDir);
  }

  /// The window as macOS composites it. Impeller's offscreen render
  /// (renderPng) loses antialiasing on macOS: noisy images, coloured fringes.
  @override
  Future<Uint8List> capture(AppDriver driver, FormFactor formFactor) async {
    final file = p.join(_logDir!, 'macos-capture.png');
    final window = await _windowId();
    final result = await Process.run('screencapture', ['-x', '-o', '-l', '$window', file]);
    if (result.exitCode != 0 || !File(file).existsSync()) {
      throw ToolException('screencapture failed: ${'${result.stdout}${result.stderr}'.trim()}. '
          'The terminal needs the Screen Recording permission (System Settings > Privacy & Security).');
    }
    final image = decode(File(file).readAsBytesSync());
    File(file).deleteSync();
    if (image.width != formFactor.width || image.height < formFactor.height) {
      throw ToolException('captured the window at ${image.width}x${image.height}, '
          'expected ${formFactor.width} wide and at least ${formFactor.height} high');
    }
    // Below the title bar. The window's rounded bottom corners are transparent.
    final content = img.copyCrop(image, x: 0, y: image.height - formFactor.height, width: formFactor.width, height: formFactor.height);
    return encode(fillCorners(content));
  }

  /// The largest window of the staged build, never an installed Sheetopia.
  Future<int> _windowId() async {
    final json = await run('osascript', [
      '-l', 'JavaScript', '-e',
      'ObjC.import("CoreGraphics"); JSON.stringify(ObjC.deepUnwrap(ObjC.castRefToObject('
          r'$.CGWindowListCopyWindowInfo($.kCGWindowListOptionAll, 0))).filter(w => w.kCGWindowLayer == 0)'
          '.map(w => [w.kCGWindowNumber, w.kCGWindowOwnerPID, w.kCGWindowBounds.Width * w.kCGWindowBounds.Height]))',
    ]);
    final windows = (jsonDecode(json) as List).cast<List>();
    final ours = <List>[];
    for (final w in windows) {
      final command = await run('ps', ['-o', 'comm=', '-p', '${w[1]}'], check: false);
      if (p.isWithin(_appDir!, command)) ours.add(w);
    }
    if (ours.isEmpty) throw ToolException('no window of the app built in $_appDir');
    ours.sort((a, b) => (b[2] as num).compareTo(a[2] as num));
    return ours.first[0] as int;
  }

  // Mac App Store: 16:10, 1280x800, 1440x900, 2560x1600 or 2880x1800.
  @override
  List<FormFactor> get formFactors => const [FormFactor('macos', 'Mac App Store', 2880, 1800)];

  @override
  // screencapture takes the backing pixels, so only 1440x900 on a Retina
  // screen gives 2880x1800 (the window may extend below the screen, see stage.dart).
  List<(int, int)> get _layouts => const [(1440, 900)];

  @override
  List<String> get _dataDirs {
    final library = p.join(Platform.environment['HOME']!, 'Library');
    return [
      p.join(library, 'Application Support', macosBundleId),
      p.join(library, 'Caches', macosBundleId),
      p.join(library, 'HTTPStorages', macosBundleId),
      p.join(library, 'Preferences', '$macosBundleId.plist'),
      p.join(library, 'Saved Application State', '$macosBundleId.savedState'),
    ];
  }

  @override
  Future<String?> unavailableReason() async => Platform.isMacOS ? null : 'needs a macOS host';
}