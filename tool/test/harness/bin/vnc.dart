// Minimal VNC (RFB 3.8) client for seeing and operating a VM's whole screen,
// including native dialogs, without any permissions inside the guest.
//
//   dart run bin/vnc.dart --url vnc://[:password@]host:port <action> [...]
//
// The URL defaults to $SHEETOPIA_VNC. Coordinates are framebuffer pixels,
// the same as in the screenshots. Actions:
//
//   screenshot <file.png> [--scale 0.5]
//   click X Y [--button left|right|middle] [--double] [--mod cmd,shift,...]
//   move X Y
//   drag X1 Y1 X2 Y2 [--steps 20] [--hold-ms 300]
//   scroll X Y [--dy N] [--dx N]        N wheel clicks, positive = down/right
//   key <combo>...                      e.g. return, escape, cmd+shift+g, f11
//   type <text>                         types text, \n becomes Return
//   size                                prints the framebuffer size
//
// Modifier names: shift, ctrl, alt (= option), cmd (= super).
// SHEETOPIA_VNC_KEYMAP=apple maps them for the macOS Virtualization.framework
// VNC server, which reads Alt as Command and Meta as Option.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:image/image.dart' as img;
import 'package:pointycastle/block/desede_engine.dart';
import 'package:pointycastle/api.dart' show KeyParameter;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('url', defaultsTo: Platform.environment['SHEETOPIA_VNC'])
    ..addOption('button', defaultsTo: 'left')
    ..addOption('mod')
    ..addOption('scale', defaultsTo: '1')
    ..addOption('steps', defaultsTo: '20')
    ..addOption('hold-ms', defaultsTo: '300')
    ..addOption('dx', defaultsTo: '0')
    ..addOption('dy', defaultsTo: '0')
    ..addFlag('double', negatable: false);
  final ArgResults a;
  try {
    a = parser.parse(arguments);
  } on FormatException catch (e) {
    _fail('${e.message}\n${parser.usage}');
  }
  final url = a.option('url');
  if (url == null || url.isEmpty) _fail('no VNC URL, pass --url or set SHEETOPIA_VNC');
  if (a.rest.isEmpty) _fail('usage: vnc <action> ... (see bin/vnc.dart)');

  final uri = Uri.parse(url);
  final password = uri.userInfo.contains(':') ? Uri.decodeComponent(uri.userInfo.split(':').last) : null;
  final VncClient client;
  try {
    client = await VncClient.connect(uri.host, uri.hasPort ? uri.port : 5900, password).timeout(const Duration(seconds: 20));
  } catch (e) {
    _fail('could not connect to ${uri.host}:${uri.port}: $e');
  }

  Timer(const Duration(seconds: 90), () => _fail('timed out after 90 s'));

  final rest = a.rest.skip(1).toList();
  int arg(int i) => int.tryParse(i < rest.length ? rest[i] : '') ?? _fail('expected a number at position ${i + 1}');
  final mods = (a.option('mod') ?? '').split(',').where((m) => m.isNotEmpty).toList();

  try {
    switch (a.rest.first) {
      case 'size':
        stdout.writeln(jsonEncode({'width': client.width, 'height': client.height}));
      case 'screenshot':
        if (rest.isEmpty) _fail('screenshot needs a file');
        var image = await client.capture();
        final scale = double.parse(a.option('scale')!);
        if (scale != 1) image = img.copyResize(image, width: (image.width * scale).round());
        File(rest.first).writeAsBytesSync(img.encodePng(image, level: 1));
        stdout.writeln(jsonEncode({'path': File(rest.first).absolute.path, 'width': image.width, 'height': image.height}));
      case 'move':
        client.pointer(arg(0), arg(1), 0);
        stdout.writeln(jsonEncode({'moved': [arg(0), arg(1)]}));
      case 'click':
        final mask = switch (a.option('button')) { 'right' => 4, 'middle' => 2, _ => 1 };
        final x = arg(0), y = arg(1);
        await client.withModifiers(mods, () async {
          client.pointer(x, y, 0);
          await _sleep(50);
          for (var i = 0; i < (a.flag('double') ? 2 : 1); i++) {
            client.pointer(x, y, mask);
            await _sleep(60);
            client.pointer(x, y, 0);
            await _sleep(60);
          }
        });
        stdout.writeln(jsonEncode({'clicked': [x, y]}));
      case 'drag':
        final x1 = arg(0), y1 = arg(1), x2 = arg(2), y2 = arg(3);
        final steps = int.parse(a.option('steps')!);
        await client.withModifiers(mods, () async {
          client.pointer(x1, y1, 0);
          await _sleep(50);
          client.pointer(x1, y1, 1);
          await _sleep(int.parse(a.option('hold-ms')!));
          for (var i = 1; i <= steps; i++) {
            client.pointer(x1 + (x2 - x1) * i ~/ steps, y1 + (y2 - y1) * i ~/ steps, 1);
            await _sleep(25);
          }
          await _sleep(int.parse(a.option('hold-ms')!));
          client.pointer(x2, y2, 0);
        });
        stdout.writeln(jsonEncode({'dragged': [x1, y1, x2, y2]}));
      case 'scroll':
        final x = arg(0), y = arg(1);
        final dy = int.parse(a.option('dy')!), dx = int.parse(a.option('dx')!);
        client.pointer(x, y, 0);
        for (var i = 0; i < dy.abs(); i++) {
          final b = dy > 0 ? 16 : 8;
          client.pointer(x, y, b);
          client.pointer(x, y, 0);
          await _sleep(20);
        }
        for (var i = 0; i < dx.abs(); i++) {
          final b = dx > 0 ? 64 : 32;
          client.pointer(x, y, b);
          client.pointer(x, y, 0);
          await _sleep(20);
        }
        stdout.writeln(jsonEncode({'scrolled': [dx, dy]}));
      case 'key':
        for (final combo in rest) {
          await client.combo(combo);
        }
        stdout.writeln(jsonEncode({'keys': rest}));
      case 'type':
        await client.typeText(rest.join(' '));
        stdout.writeln(jsonEncode({'typed': rest.join(' ')}));
      default:
        _fail('unknown action ${a.rest.first}');
    }
    await client.flush();
  } catch (e) {
    stderr.writeln('error: $e');
    await client.close();
    exit(1);
  }
  await client.close();
  exit(0);
}

Future<void> _sleep(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}

/// Buffers socket data so the protocol can be read in exact chunks.
class _Reader {
  final _chunks = <Uint8List>[];
  var _available = 0;
  Completer<void>? _waiting;
  Object? _error;
  var _done = false;

  _Reader(Stream<Uint8List> stream) {
    stream.listen(
      (data) {
        _chunks.add(data);
        _available += data.length;
        _wake();
      },
      onError: (Object e) {
        _error = e;
        _wake();
      },
      onDone: () {
        _done = true;
        _wake();
      },
    );
  }

  void _wake() {
    final w = _waiting;
    _waiting = null;
    w?.complete();
  }

  Future<Uint8List> read(int n) async {
    while (_available < n) {
      if (_error != null) throw _error!;
      if (_done) throw const SocketException('connection closed by the VNC server');
      _waiting = Completer<void>();
      await _waiting!.future;
    }
    final out = Uint8List(n);
    var offset = 0;
    while (offset < n) {
      final chunk = _chunks.first;
      final take = (n - offset) < chunk.length ? n - offset : chunk.length;
      out.setRange(offset, offset + take, chunk);
      offset += take;
      if (take == chunk.length) {
        _chunks.removeAt(0);
      } else {
        _chunks[0] = Uint8List.sublistView(chunk, take);
      }
    }
    _available -= n;
    return out;
  }

  Future<int> u8() async => (await read(1))[0];
  Future<int> u16() async => ByteData.sublistView(await read(2)).getUint16(0);
  Future<int> u32() async => ByteData.sublistView(await read(4)).getUint32(0);
}

class VncClient {
  final Socket _socket;
  final _Reader _in;
  int width = 0, height = 0;

  VncClient._(this._socket) : _in = _Reader(_socket);

  static Future<VncClient> connect(String host, int port, String? password) async {
    final socket = await Socket.connect(host, port);
    socket.setOption(SocketOption.tcpNoDelay, true);
    final c = VncClient._(socket);
    await c._handshake(password);
    return c;
  }

  Future<void> _handshake(String? password) async {
    final version = ascii.decode(await _in.read(12));
    if (!version.startsWith('RFB ')) throw StateError('not a VNC server: $version');
    _socket.add(ascii.encode('RFB 003.008\n'));
    final count = await _in.u8();
    if (count == 0) throw StateError('VNC server refused: ${await _reason()}');
    final types = await _in.read(count);
    if (types.contains(1) && (password == null || !types.contains(2))) {
      _socket.add([1]);
    } else if (types.contains(2)) {
      if (password == null) throw StateError('VNC server wants a password, pass it in the URL');
      _socket.add([2]);
      final challenge = await _in.read(16);
      _socket.add(_vncAuthResponse(password, challenge));
    } else {
      throw StateError('no supported VNC security type in $types (need None or VNC auth)');
    }
    if (await _in.u32() != 0) throw StateError('VNC authentication failed: ${await _reason()}');

    _socket.add([1]); // ClientInit, shared
    width = await _in.u16();
    height = await _in.u16();
    await _in.read(16); // server pixel format, replaced below
    await _in.read(await _in.u32()); // desktop name

    // 32 bit little endian true colour, red at bit 16.
    _socket.add([0, 0, 0, 0, 32, 24, 0, 1, 0, 255, 0, 255, 0, 255, 16, 8, 0, 0, 0, 0]);
    final enc = ByteData(4 + 2 * 4)
      ..setUint8(0, 2)
      ..setUint16(2, 2)
      ..setInt32(4, 0) // Raw
      ..setInt32(8, -223); // DesktopSize
    _socket.add(enc.buffer.asUint8List());
  }

  Future<String> _reason() async {
    try {
      return utf8.decode(await _in.read(await _in.u32()));
    } catch (_) {
      return 'no reason given';
    }
  }

  static List<int> _vncAuthResponse(String password, Uint8List challenge) {
    // VNC uses DES with the bits of each key byte reversed.
    final key = Uint8List(8);
    final pw = latin1.encode(password);
    for (var i = 0; i < 8 && i < pw.length; i++) {
      var b = pw[i], r = 0;
      for (var bit = 0; bit < 8; bit++) {
        r = (r << 1) | (b & 1);
        b >>= 1;
      }
      key[i] = r;
    }
    final des = DESedeEngine()..init(true, KeyParameter(Uint8List.fromList([...key, ...key, ...key])));
    final out = Uint8List(16);
    des.processBlock(challenge, 0, out, 0);
    des.processBlock(challenge, 8, out, 8);
    return out;
  }

  /// Requests the full screen and waits until every pixel arrived.
  Future<img.Image> capture() async {
    var image = img.Image(width: width, height: height);
    var covered = 0;
    _request(incremental: false);
    while (covered < width * height) {
      final type = await _in.u8();
      switch (type) {
        case 0: // FramebufferUpdate
          await _in.read(1);
          final rects = await _in.u16();
          for (var r = 0; r < rects; r++) {
            final x = await _in.u16(), y = await _in.u16(), w = await _in.u16(), h = await _in.u16();
            final encoding = ByteData.sublistView(await _in.read(4)).getInt32(0);
            if (encoding == -223) {
              width = w;
              height = h;
              image = img.Image(width: width, height: height);
              covered = 0;
              _request(incremental: false);
              continue;
            }
            if (encoding != 0) throw StateError('unexpected VNC encoding $encoding');
            final pixels = await _in.read(w * h * 4);
            for (var row = 0; row < h; row++) {
              for (var col = 0; col < w; col++) {
                final o = (row * w + col) * 4;
                image.setPixelRgb(x + col, y + row, pixels[o + 2], pixels[o + 1], pixels[o]);
              }
            }
            covered += w * h;
          }
          // An incremental request is only answered once the screen changes.
          if (covered < width * height) _request(incremental: false);
        case 1: // SetColourMapEntries
          await _in.read(3);
          await _in.read(await _in.u16() * 6);
        case 2: // Bell
          break;
        case 3: // ServerCutText
          await _in.read(3);
          await _in.read(await _in.u32());
        default:
          throw StateError('unknown VNC server message $type');
      }
    }
    return image;
  }

  void _request({required bool incremental}) {
    final b = ByteData(10)
      ..setUint8(0, 3)
      ..setUint8(1, incremental ? 1 : 0)
      ..setUint16(6, width)
      ..setUint16(8, height);
    _socket.add(b.buffer.asUint8List());
  }

  void pointer(int x, int y, int mask) {
    final b = ByteData(6)
      ..setUint8(0, 5)
      ..setUint8(1, mask)
      ..setUint16(2, x.clamp(0, width - 1))
      ..setUint16(4, y.clamp(0, height - 1));
    _socket.add(b.buffer.asUint8List());
  }

  void key(int keysym, bool down) {
    final b = ByteData(8)
      ..setUint8(0, 4)
      ..setUint8(1, down ? 1 : 0)
      ..setUint32(4, keysym);
    _socket.add(b.buffer.asUint8List());
  }

  static const _x11Modifiers = {
    'shift': 0xffe1,
    'ctrl': 0xffe3,
    'control': 0xffe3,
    'alt': 0xffe9,
    'option': 0xffe9,
    'cmd': 0xffeb,
    'super': 0xffeb,
    'meta': 0xffe7,
  };

  static const _appleModifiers = {
    'shift': 0xffe1,
    'ctrl': 0xffe3,
    'control': 0xffe3,
    'alt': 0xffe7,
    'option': 0xffe7,
    'cmd': 0xffe9,
    'super': 0xffe9,
    'meta': 0xffe9,
  };

  static final _modifiers = Platform.environment['SHEETOPIA_VNC_KEYMAP'] == 'apple' ? _appleModifiers : _x11Modifiers;

  static const _named = {
    'return': 0xff0d,
    'enter': 0xff0d,
    'escape': 0xff1b,
    'esc': 0xff1b,
    'tab': 0xff09,
    'backspace': 0xff08,
    'delete': 0xffff,
    'space': 0x20,
    'home': 0xff50,
    'end': 0xff57,
    'pageup': 0xff55,
    'pagedown': 0xff56,
    'left': 0xff51,
    'up': 0xff52,
    'right': 0xff53,
    'down': 0xff54,
  };

  static int _keysym(String name) {
    final lower = name.toLowerCase();
    if (_named.containsKey(lower)) return _named[lower]!;
    final f = RegExp(r'^f(\d{1,2})$').firstMatch(lower);
    if (f != null) return 0xffbe + int.parse(f.group(1)!) - 1;
    if (name.runes.length == 1) return _charKeysym(name.runes.first);
    throw ArgumentError('unknown key $name');
  }

  static int _charKeysym(int rune) => rune < 0x100 ? rune : 0x01000000 | rune;

  Future<void> withModifiers(List<String> mods, Future<void> Function() action) async {
    final syms = mods.map((m) => _modifiers[m.toLowerCase()] ?? (throw ArgumentError('unknown modifier $m'))).toList();
    for (final s in syms) {
      key(s, true);
      await _sleep(30);
    }
    try {
      await action();
    } finally {
      for (final s in syms.reversed) {
        key(s, false);
        await _sleep(30);
      }
    }
  }

  /// Presses a combo like `cmd+shift+g` or `return`.
  Future<void> combo(String combo) async {
    final parts = combo.split('+');
    final main = parts.removeLast();
    await withModifiers(parts, () async {
      final sym = _keysym(main.isEmpty ? '+' : main);
      key(sym, true);
      await _sleep(40);
      key(sym, false);
      await _sleep(40);
    });
  }

  static const _shifted = '~!@#\$%^&*()_+{}|:"<>?';

  Future<void> typeText(String text) async {
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '\n') {
        await combo('return');
        continue;
      }
      // Hold shift for characters that need it on a US layout, servers
      // that synthesize it themselves are fine with that too.
      final needsShift = (rune >= 0x41 && rune <= 0x5a) || _shifted.contains(ch);
      await withModifiers(needsShift ? ['shift'] : [], () async {
        key(_charKeysym(rune), true);
        await _sleep(15);
        key(_charKeysym(rune), false);
        await _sleep(15);
      });
    }
  }

  Future<void> flush() async {
    await _socket.flush();
    await _sleep(100);
  }

  Future<void> close() async {
    try {
      await _socket.flush();
    } catch (_) {}
    _socket.destroy();
  }
}
