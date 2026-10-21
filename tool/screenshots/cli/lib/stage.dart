import 'dart:io';

import 'package:path/path.dart' as p;

import 'util.dart';

/// Entry point of the screenshot build, relative to the repository.
const entryPoint = 'tool/screenshots/app/main_screenshots.dart';

/// Bundle id of the macOS screenshot build, so it never shares its data
/// directories with an installed Sheetopia.
const macosBundleId = 'de.julianh.sheetopia.screenshots';

/// A copy of the working tree (tracked and untracked, not ignored files) with
/// the screenshot patches applied. The repository itself is never touched.
class Stage {
  final String dir;
  final String version;

  Stage._(this.dir, this.version);

  static Future<Stage> create(String dir, {required String logFile}) async {
    log('staging the working tree into $dir');
    Directory(dir).createSync(recursive: true);
    final files = await Process.run('git', ['ls-files', '-co', '--exclude-standard', '-z'], workingDirectory: repoDir);
    if (files.exitCode != 0) throw ToolException('git ls-files failed: ${files.stderr}');
    final existing = (files.stdout as String)
        .split('\x00')
        .where((f) => f.isNotEmpty && FileSystemEntity.typeSync(p.join(repoDir, f), followLinks: false) != FileSystemEntityType.notFound)
        .toList();
    // tar keeps symlinks and executable bits (gradlew).
    final list = File(p.join(p.dirname(dir), 'stage-files.txt'))..writeAsStringSync(existing.join('\n'));
    final pack = await Process.start('tar', ['-cf', '-', '-T', list.path], workingDirectory: repoDir);
    final unpack = await Process.start('tar', ['-xf', '-'], workingDirectory: dir);
    final errors = StringBuffer();
    pack.stderr.transform(systemEncoding.decoder).forEach(errors.write);
    unpack.stderr.transform(systemEncoding.decoder).forEach(errors.write);
    unpack.stdout.drain<void>();
    await pack.stdout.pipe(unpack.stdin);
    final codes = await Future.wait([pack.exitCode, unpack.exitCode]);
    if (codes.any((c) => c != 0)) throw ToolException('copying the working tree failed: $errors');
    list.deleteSync();

    _patch(dir, 'lib/ui/home/sync_icon.dart', RegExp(r'valueListenable: syncRepository\.state,'),
        'valueListenable: ValueNotifier(SyncState.success),');
    _patch(
      dir,
      'lib/data/repositories/sync/sync_repository.dart',
      RegExp(r'encryptedStorage \?\?\s*\(Platform\.isLinux\s*\?\s*EncryptedStorageLinux\(keyValueRepo: keyValue\)\s*:\s*EncryptedStorageSecureStorage\(\)\)'),
      'encryptedStorage ?? _ScreenshotMemoryStorage()',
      append: _memoryStorage,
    );
    _patch(dir, 'macos/Runner/Configs/AppInfo.xcconfig', RegExp(r'^PRODUCT_BUNDLE_IDENTIFIER = .*$', multiLine: true),
        'PRODUCT_BUNDLE_IDENTIFIER = $macosBundleId');

    // Gradle reads the release signing config of every build. Profile builds
    // are signed with the debug key, the real keystore stays out of the stage.
    File(p.join(dir, 'android', 'key.properties')).writeAsStringSync('keyAlias=unused\nkeyPassword=unused\nstorePassword=unused\n');

    final version = _version(dir);
    log('flutter pub get (stage)');
    await run('flutter', ['pub', 'get'], workingDirectory: dir, logFile: logFile);
    return Stage._(dir, version);
  }

  /// Reuses an earlier stage, with the driver entry points refreshed from the
  /// working tree.
  static Stage existing(String dir) {
    if (!Directory(dir).existsSync()) throw ToolException('no staged tree at $dir, was the run made with --keep?');
    for (final sub in ['tool/screenshots/app', 'tool/test/app']) {
      for (final file in Directory(p.join(repoDir, sub)).listSync().whereType<File>()) {
        file.copySync(p.join(dir, sub, p.basename(file.path)));
      }
    }
    return Stage._(dir, _version(dir));
  }

  static String _version(String dir) {
    final pubspec = File(p.join(dir, 'pubspec.yaml')).readAsStringSync();
    final version = RegExp(r'^version: ([^+\s]+)', multiLine: true).firstMatch(pubspec)?.group(1);
    if (version == null) throw ToolException('no version in ${p.join(dir, 'pubspec.yaml')}');
    return version;
  }

  /// Replaces exactly one match, so a changed source fails loudly instead of
  /// building without the patch.
  static void _patch(String dir, String file, RegExp pattern, String replacement, {String append = ''}) {
    final f = File(p.join(dir, file));
    final source = f.readAsStringSync();
    final matches = pattern.allMatches(source).length;
    if (matches != 1) {
      throw ToolException('patching $file: expected one match of ${pattern.pattern}, found $matches. '
          'Update tool/screenshots/cli/lib/stage.dart to the changed source.');
    }
    f.writeAsStringSync(source.replaceFirst(pattern, replacement) + append);
  }
}

// The screenshot build must never read or write the login of the Sheetopia
// installed on this machine, which lives in the system keyring.
const _memoryStorage = '''

class _ScreenshotMemoryStorage implements EncryptedStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}
''';
