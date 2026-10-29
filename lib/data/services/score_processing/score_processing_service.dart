/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:pdfrx/pdfrx.dart';
import 'package:sheetopia/data/services/score_processing/background_color.dart';

class ScoreProcessingResult {
  final int pageCount;
  final int? backgroundColor;

  const ScoreProcessingResult({
    required this.pageCount,
    required this.backgroundColor,
  });
}

class _Start {
  final SendPort reply;

  const _Start(this.reply);
}

class _RenderedPage {
  final int width;
  final int height;
  final TransferableTypedData bgra;

  const _RenderedPage({
    required this.width,
    required this.height,
    required this.bgra,
  });
}

class _Finish {
  const _Finish();
}

const _workerExited = "exited";

class _Worker {
  final Isolate isolate;
  final SendPort sendPort;
  SendPort? reply;
  bool exited = false;

  _Worker(this.isolate, this.sendPort);
}

// Pages are rendered by pdfrx on its own pdfium worker.
class ScoreProcessingService {
  static const int _renderSize = 768;

  _Worker? _worker;
  Future<_Worker>? _starting;

  Future<ScoreProcessingResult> processPdf(String path) async {
    final worker = await _ensureWorker();
    if (worker.exited) throw StateError("Score processing isolate exited");
    final port = ReceivePort();
    final replies = StreamIterator<Object?>(port);
    worker.reply = port.sendPort;
    try {
      worker.sendPort.send(_Start(port.sendPort));
      // one page is analyzed while the next one renders
      var unacknowledged = 0;
      await Pdfrx.runAsBackgroundWork(() async {
        final pdf = await PdfDocument.openFile(path);
        try {
          for (final page in pdf.pages) {
            final rendered = await _renderPage(page);
            if (rendered == null) continue;
            if (unacknowledged > 0) {
              await _nextReply(replies);
              unacknowledged--;
            }
            worker.sendPort.send(rendered);
            unacknowledged++;
          }
        } finally {
          await pdf.dispose();
        }
      });
      worker.sendPort.send(const _Finish());
      for (; unacknowledged > 0; unacknowledged--) {
        await _nextReply(replies);
      }
      return await _nextReply(replies) as ScoreProcessingResult;
    } finally {
      if (worker.reply == port.sendPort) worker.reply = null;
      await replies.cancel();
      port.close();
    }
  }

  void stop() {
    _worker?.isolate.kill(priority: Isolate.immediate);
    _worker = null;
  }

  Future<_Worker> _ensureWorker() {
    if (_worker != null) return Future.value(_worker);
    return _starting ??= _spawn().whenComplete(() => _starting = null);
  }

  Future<_Worker> _spawn() async {
    final initPort = ReceivePort();
    final exitPort = ReceivePort();
    final exited = Completer<void>();
    exitPort.listen((_) {
      exitPort.close();
      exited.complete();
    });
    try {
      final isolate = await Isolate.spawn(
        _workerMain,
        initPort.sendPort,
        onExit: exitPort.sendPort,
        debugName: "score processing",
      );
      final sendPort = await Future.any([
        initPort.first,
        exited.future.then((_) => null),
      ]);
      if (sendPort is! SendPort) {
        throw StateError("Score processing isolate exited during startup");
      }
      final worker = _Worker(isolate, sendPort);
      exited.future.then((_) {
        worker.exited = true;
        worker.reply?.send(_workerExited);
        if (_worker == worker) _worker = null;
      });
      return _worker = worker;
    } catch (_) {
      exitPort.close();
      rethrow;
    } finally {
      initPort.close();
    }
  }

  Future<Object?> _nextReply(StreamIterator<Object?> replies) async {
    if (!await replies.moveNext()) {
      throw StateError("Score processing reply port closed");
    }
    return switch (replies.current) {
      RemoteError() && final error => throw error,
      _workerExited => throw StateError("Score processing isolate exited"),
      final reply => reply,
    };
  }

  Future<_RenderedPage?> _renderPage(PdfPage page) async {
    final scale = _renderSize / max(page.width, page.height);
    final width = max(1, (page.width * scale).round());
    final height = max(1, (page.height * scale).round());
    final image = await page.render(
      width: width,
      height: height,
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
      // smoothing downscaled scans costs more than half of the render time
      flags: PdfPageRenderFlags.noSmoothImage,
      priority: PdfPageRenderPriority.low,
    );
    if (image == null) return null;
    try {
      return _RenderedPage(
        width: image.width,
        height: image.height,
        bgra: TransferableTypedData.fromList([image.pixels]),
      );
    } finally {
      image.dispose();
    }
  }
}

void _workerMain(SendPort initPort) {
  final port = ReceivePort();
  initPort.send(port.sendPort);
  SendPort? reply;
  var pageCount = 0;
  final backgrounds = <PageBackground>[];
  port.listen((message) {
    try {
      switch (message) {
        case _Start():
          reply = message.reply;
          pageCount = 0;
          backgrounds.clear();
        case _RenderedPage():
          final background = estimatePageBackground(
            PageBitmap(
              width: message.width,
              height: message.height,
              bgra: message.bgra.materialize().asUint8List(),
            ),
          );
          pageCount++;
          if (background != null) backgrounds.add(background);
          reply?.send(true);
        case _Finish():
          reply?.send(
            ScoreProcessingResult(
              pageCount: pageCount,
              backgroundColor: combinePageBackgrounds(backgrounds),
            ),
          );
          backgrounds.clear();
      }
    } catch (e, st) {
      reply?.send(RemoteError(e.toString(), st.toString()));
    }
  });
}
