// Captures the README and store screenshots of Sheetopia with the demo
// library, see tool/screenshots/README.md.

import 'dart:io';

import 'package:args/args.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sheetopia_screenshots/driver.dart';
import 'package:sheetopia_screenshots/feature_graphic.dart';
import 'package:sheetopia_screenshots/images.dart';
import 'package:sheetopia_screenshots/library.dart';
import 'package:sheetopia_screenshots/scenes.dart';
import 'package:sheetopia_screenshots/stage.dart';
import 'package:sheetopia_screenshots/target.dart';
import 'package:sheetopia_screenshots/targets/android.dart';
import 'package:sheetopia_screenshots/targets/desktop.dart';
import 'package:sheetopia_screenshots/targets/ios.dart';
import 'package:sheetopia_screenshots/targets/linux.dart';
import 'package:sheetopia_screenshots/util.dart';

final _targets = <Target>[LinuxTarget(), MacosTarget(), AndroidTarget(), IosTarget()];

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('platforms', help: 'comma separated, e.g. linux,android (default: ask)')
    ..addOption('form-factors', help: 'comma separated form factor ids (default: all of the platforms)')
    ..addOption('scenes', help: 'comma separated scene names (default: all)')
    ..addFlag('readme', negatable: false, help: 'copy the Linux screenshots to screenshots/ and point README.md at them')
    ..addFlag('keep', negatable: false, help: 'keep the staged sources and builds in the run directory')
    ..addOption('stage', help: 'reuse the staged tree (and builds) of an earlier run directory')
    ..addFlag('explore', negatable: false, help: 'start the first form factor with the library imported and wait, '
        'for writing scenes with tool/test/harness/bin/drive.dart')
    ..addOption('feature-graphic', help: 'only render the Google Play feature graphic again from an earlier run directory')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n${parser.usage}');
    exit(2);
  }
  if (args.flag('help')) {
    stdout.writeln('Usage: tool/screenshots/screenshots.sh [options]\n\n${parser.usage}\n\n'
        'Scenes: ${scenes.map((s) => s.name).join(', ')}');
    return;
  }

  // Emulators, simulators and the headless KWin must not outlive the tool.
  for (final signal in [ProcessSignal.sigint, if (!Platform.isWindows) ProcessSignal.sigterm]) {
    signal.watch().listen((_) async {
      log('interrupted, cleaning up');
      for (final target in _targets) {
        await target.close().catchError((Object e) => log('cleaning up ${target.id} failed: $e'));
      }
      exit(130);
    });
  }

  try {
    exitCode = await _run(args);
  } on ToolException catch (e) {
    log('error: $e');
    exitCode = 1;
  }
  exit(exitCode);
}

Future<int> _run(ArgResults args) async {
  final featureGraphicRun = args.option('feature-graphic');
  if (featureGraphicRun != null) {
    final runDir = p.absolute(featureGraphicRun);
    final logDir = p.join(runDir, 'logs');
    Directory(logDir).createSync(recursive: true);
    final file = await renderFeatureGraphic(p.join(runDir, 'screenshots'), logDir);
    if (file == null) throw ToolException('$runDir has no macos or linux library and annotate screenshots');
    log('feature graphic in $file');
    return 0;
  }

  final platformFilter = args.option('platforms')?.split(',');
  _checkNames('platforms', platformFilter, _targets.map((t) => t.id));
  final formFactorFilter = args.option('form-factors')?.split(',');
  _checkNames('form factors', formFactorFilter, _targets.expand((t) => t.formFactors).map((f) => f.id));
  final sceneFilter = args.option('scenes')?.split(',');
  _checkNames('scenes', sceneFilter, scenes.map((s) => s.name));
  final chosenScenes = scenes.where((s) => sceneFilter?.contains(s.name) ?? true).toList();
  if (args.flag('readme') && sceneFilter != null) {
    log('warning: --readme with --scenes moves only these scenes to the new version');
  }

  final available = <Target>[];
  for (final target in _targets) {
    final reason = await target.unavailableReason();
    if (reason == null) {
      available.add(target);
    } else if (platformFilter?.contains(target.id) ?? false) {
      throw ToolException('${target.id} is not available: $reason');
    }
  }
  if (available.isEmpty) throw ToolException('no platform can be captured on this host');

  final selected = platformFilter != null ? available.where((t) => platformFilter.contains(t.id)).toList() : _ask(available);
  if (selected.isEmpty) throw ToolException('no platform selected');
  if (formFactorFilter != null && !selected.expand((t) => t.formFactors).any((f) => formFactorFilter.contains(f.id))) {
    throw ToolException('none of the form factors ${formFactorFilter.join(', ')} belongs to the selected platforms');
  }

  final started = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final runId = '${started.year}-${two(started.month)}-${two(started.day)}_${two(started.hour)}${two(started.minute)}${two(started.second)}';
  final runDir = p.join(repoDir, 'tool', 'screenshots', 'out', runId);
  final logDir = p.join(runDir, 'logs');
  Directory(logDir).createSync(recursive: true);
  log('run directory $runDir');

  final libraryZip = p.join(runDir, 'demo-library.zip');
  log('building the demo library');
  final python = await which('python3') ? 'python3' : 'python';
  await run(python, [
    p.join(repoDir, 'tool', 'demo_library', 'build.py'),
    '-o', libraryZip,
    '--now', '${started.year}-${two(started.month)}-${two(started.day)}T${two(started.hour)}:${two(started.minute)}',
  ], logFile: p.join(logDir, 'demo-library.log'));
  final library = Library.read(libraryZip);

  final reuse = args.option('stage');
  final stage = reuse != null
      ? Stage.existing(p.join(p.absolute(reuse), 'stage'))
      : await Stage.create(p.join(runDir, 'stage'), logFile: p.join(logDir, 'stage.log'));
  if (reuse != null) log('reusing ${stage.dir}');

  final failures = <String>[];
  final written = <String, List<String>>{};
  for (final target in selected) {
    try {
      await target.build(stage, logDir);
      for (final formFactor in target.formFactors) {
        if (formFactorFilter != null && !formFactorFilter.contains(formFactor.id)) continue;
        log('${formFactor.id}: ${formFactor.description}');
        final driver = await target.start(stage, formFactor, logDir);
        await _import(driver, library);
        if (args.flag('explore')) {
          log('exploring, press enter to stop. Drive the app with:\n'
              '  (cd tool/test/harness && dart run bin/drive.dart --url ${driver.url} describe)');
          await stdin.first;
          await target.close();
          log('staged tree kept, reuse it with --stage $runDir');
          return 0;
        }
        final outDir = p.join(runDir, 'screenshots', formFactor.id);
        Directory(outDir).createSync(recursive: true);
        for (final scene in chosenScenes) {
          try {
            final file = p.join(outDir, formFactor.readme ? '${scene.name}-${stage.version}.png' : '${scene.name}.png');
            await _capture(target, driver, formFactor, scene, library, file);
            (written[formFactor.id] ??= []).add(file);
            log('  ${scene.name}');
          } catch (e) {
            failures.add('${formFactor.id} ${scene.name}: $e');
            log('  ${scene.name} FAILED: $e');
          }
        }
        await target.finish(formFactor);
      }
    } catch (e) {
      failures.add('${target.id}: $e');
      log('${target.id} FAILED: $e');
    } finally {
      await target.close();
    }
  }

  try {
    final file = await renderFeatureGraphic(p.join(runDir, 'screenshots'), logDir);
    if (file != null) log('feature graphic in $file');
  } catch (e) {
    failures.add('feature graphic: $e');
    log('feature graphic FAILED: $e');
  }

  if (args.flag('readme')) {
    final linux = written['linux'];
    if (linux == null || failures.any((f) => f.startsWith('linux'))) {
      failures.add('README not updated: the Linux screenshots are missing or incomplete');
    } else {
      _updateReadme(linux, stage.version);
    }
  }

  if (!args.flag('keep') && reuse == null) {
    log('removing the staged tree (--keep keeps it)');
    Directory(stage.dir).deleteSync(recursive: true);
  }

  log('screenshots in ${p.join(runDir, 'screenshots')}');
  if (failures.isNotEmpty) {
    log('${failures.length} failure(s):\n  ${failures.join('\n  ')}');
    return 1;
  }
  return 0;
}

void _checkNames(String what, List<String>? names, Iterable<String> known) {
  final unknown = names?.where((n) => !known.contains(n)).toList() ?? [];
  if (unknown.isNotEmpty) throw ToolException('unknown $what ${unknown.join(', ')}, known are ${known.join(', ')}');
}

List<Target> _ask(List<Target> available) {
  stdout.writeln('Platforms available on this machine:');
  for (final (i, t) in available.indexed) {
    final sets = t.formFactors.map((f) => '${f.id} (${f.width}x${f.height})').join(', ');
    stdout.writeln('  ${i + 1}) ${t.id.padRight(8)} $sets');
  }
  stdout.write('Capture which? Numbers or names, separated by spaces or commas [all]: ');
  final answer = stdin.readLineSync()?.trim() ?? '';
  if (answer.isEmpty || answer == 'all') return available;
  final picked = <Target>[];
  for (final part in answer.split(RegExp(r'[\s,]+'))) {
    final index = int.tryParse(part);
    final target = index != null && index >= 1 && index <= available.length
        ? available[index - 1]
        : available.where((t) => t.id == part).firstOrNull;
    if (target == null) throw ToolException('unknown platform $part');
    if (!picked.contains(target)) picked.add(target);
  }
  return picked;
}

Future<void> _import(AppDriver driver, Library library) async {
  log('importing the demo library');
  await driver.settle(timeoutMs: 15000);
  await driver.upload('demo-library.zip', File(library.path).readAsBytesSync());
  final result = await driver.call('import', {'name': 'demo-library.zip'});
  if (result['imported'] != true) throw ToolException('importing the demo library failed: $result');
  await warmUp(driver);
}

Future<void> _capture(Target target, AppDriver driver, FormFactor formFactor, Scene scene, Library library, String file) async {
  final context = SceneContext(driver, library, formFactor, await driver.size());
  await driver.unfocus();
  await driver.theme('dark');
  await driver.call('reset');
  await driver.settle();
  img.Image image;
  try {
    await scene.prepare(context);
    await context.ready();

    image = decode(await target.capture(driver, formFactor));
    if (scene.lightAndDark) {
      await driver.theme('light');
      await context.ready();
      final light = decode(await target.capture(driver, formFactor));
      await driver.theme('dark');
      image = diagonal(light, image);
    }
  } finally {
    await scene.cleanup?.call(context).catchError((Object e) => log('  ${scene.name} cleanup failed: $e'));
  }
  if (image.width != formFactor.width || image.height != formFactor.height) {
    File(file.replaceFirst(RegExp(r'\.png$'), '.wrong-size.png')).writeAsBytesSync(encode(image));
    throw ToolException('captured ${image.width}x${image.height}, expected ${formFactor.width}x${formFactor.height}');
  }
  if (!formFactor.readme) image = opaque(image);
  File(file).writeAsBytesSync(encode(image));
}

/// Copies the Linux screenshots to screenshots/ and points README.md at them.
/// Screenshots of older versions stay, git shows them as no longer used.
void _updateReadme(List<String> files, String version) {
  final readme = File(p.join(repoDir, 'README.md'));
  var text = readme.readAsStringSync();
  for (final file in files) {
    final name = p.basename(file);
    File(file).copySync(p.join(repoDir, 'screenshots', name));
    final scene = name.substring(0, name.length - '-$version.png'.length);
    text = text.replaceAll(RegExp('screenshots/${RegExp.escape(scene)}-[^"/]+\\.png'), 'screenshots/$name');
  }
  readme.writeAsStringSync(text);
  log('updated README.md and screenshots/ for $version');
}
