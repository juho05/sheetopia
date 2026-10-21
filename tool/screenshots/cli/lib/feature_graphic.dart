import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import 'images.dart';
import 'util.dart';

const _title = 'Sheetopia';
const _taglineLines = ['Your sheet music.', 'Organized, annotated, synced.'];
const _chips = ['Annotations', 'Setlists', 'MIDI page turns', 'Practice'];

/// Form factors to take the screenshots from, first match wins, with the
/// height of the window decoration to crop away.
const _sources = {'macos': 0, 'linux': 56};

const _browsers = [
  'chromium',
  'chromium-browser',
  'google-chrome',
  'google-chrome-stable',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
];

/// Renders the 1024x500 Google Play feature graphic from the library and
/// annotate screenshots in [screenshotsDir] to feature-graphic.png in it.
/// Returns null if the run has no desktop screenshots.
Future<String?> renderFeatureGraphic(String screenshotsDir, String logDir) async {
  final source = _findSource(screenshotsDir);
  if (source == null) return null;
  final (library, annotate, crop) = source;

  String? browser;
  for (final candidate in _browsers) {
    if (p.isAbsolute(candidate) ? File(candidate).existsSync() : await which(candidate)) {
      browser = candidate;
      break;
    }
  }
  if (browser == null) throw ToolException('no Chrome or Chromium installed to render the feature graphic');

  final work = Directory(p.join(p.dirname(screenshotsDir), 'feature-graphic'));
  if (work.existsSync()) work.deleteSync(recursive: true);
  work.createSync(recursive: true);
  for (final (from, to) in [(library, 'library.png'), (annotate, 'annotate.png')]) {
    var image = decode(File(from).readAsBytesSync());
    image = img.copyCrop(image, x: 0, y: crop, width: image.width, height: image.height - crop);
    File(p.join(work.path, to)).writeAsBytesSync(encode(image));
  }
  File(p.join(repoDir, 'assets', 'icon', 'sheetopia.png')).copySync(p.join(work.path, 'icon.png'));
  final html = File(p.join(work.path, 'feature-graphic.html'))..writeAsStringSync(_html());

  final capture = p.join(work.path, 'capture.png');
  await run(browser, [
    '--headless',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--user-data-dir=${p.join(work.path, 'profile')}',
    '--force-device-scale-factor=1',
    '--window-size=1024,500',
    '--screenshot=$capture',
    Uri.file(html.path).toString(),
  ], logFile: p.join(logDir, 'feature-graphic.log'));
  final image = decode(File(capture).readAsBytesSync());
  if (image.width != 1024 || image.height != 500) {
    throw ToolException('the feature graphic is ${image.width}x${image.height}, expected 1024x500');
  }
  final out = p.join(screenshotsDir, 'feature-graphic.png');
  File(out).writeAsBytesSync(encode(opaque(image)));
  return out;
}

(String, String, int)? _findSource(String screenshotsDir) {
  for (final MapEntry(key: formFactor, value: crop) in _sources.entries) {
    final dir = Directory(p.join(screenshotsDir, formFactor));
    if (!dir.existsSync()) continue;
    String? find(String scene) => dir
        .listSync()
        .map((f) => f.path)
        .where((f) => RegExp('^${RegExp.escape(scene)}(-.+)?\\.png\$').hasMatch(p.basename(f)))
        .firstOrNull;
    final library = find('library'), annotate = find('annotate');
    if (library != null && annotate != null) return (library, annotate, crop);
  }
  return null;
}

String _html() {
  const e = HtmlEscape();
  final tagline = _taglineLines.map(e.convert).join('<br>');
  final chips = _chips.map((c) => '<span class="chip">${e.convert(c)}</span>').join();
  return '''
<!doctype html>
<html><head><meta charset="utf-8">
<style>
  html, body { margin: 0; width: 1024px; height: 500px; overflow: hidden; }
  body {
    font-family: "Roboto", "Noto Sans", "Helvetica Neue", sans-serif;
    background: radial-gradient(circle at 80% 20%, #7a12c4 0%, transparent 55%),
                linear-gradient(160deg, #6200a7 0%, #3d0b8f 55%, #290f7d 100%);
    position: relative; color: #fff;
  }
  .glow { position: absolute; width: 520px; height: 520px; border-radius: 50%;
    background: radial-gradient(circle, rgba(185,120,255,.35), transparent 65%);
    right: 40px; top: -40px; }
  .left { position: absolute; left: 64px; top: 0; bottom: 0; width: 430px;
    display: flex; flex-direction: column; justify-content: center; }
  .brand { display: flex; align-items: center; gap: 18px; }
  .brand img { width: 84px; height: 84px; border-radius: 20px;
    box-shadow: 0 8px 24px rgba(0,0,0,.35); }
  h1 { font-size: 58px; font-weight: 700; margin: 0; letter-spacing: -1px; }
  p { font-size: 27px; line-height: 1.3; margin: 26px 0 0; font-weight: 400; color: #ece0ff; }
  .chips { display: flex; flex-wrap: nowrap; gap: 6px; margin-top: 24px; }
  .chip { font-size: 14px; padding: 5px 11px; white-space: nowrap; border-radius: 999px;
    background: rgba(255,255,255,.14); border: 1px solid rgba(255,255,255,.22); }
  .device { position: absolute; border-radius: 22px; background: #111;
    padding: 12px; box-shadow: 0 30px 60px rgba(10,0,40,.55); }
  .device img { display: block; border-radius: 10px; }
  .back { left: 640px; top: 215px; transform: rotate(-4deg); }
  .back img { width: 470px; }
  .front { left: 480px; top: 40px; transform: rotate(-8deg); }
  .front img { width: 500px; }
</style></head>
<body>
  <div class="glow"></div>
  <div class="device back"><img src="annotate.png"></div>
  <div class="device front"><img src="library.png"></div>
  <div class="left">
    <div class="brand"><img src="icon.png"><h1>${e.convert(_title)}</h1></div>
    <p>$tagline</p>
    <div class="chips">$chips</div>
  </div>
</body></html>
''';
}
