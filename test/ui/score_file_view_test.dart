/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/score/score_file_view.dart';

class FakeFileView implements ScoreFileView {
  final String name;
  final List<String> log;

  FakeFileView(this.name, this.log);

  @override
  void nextPage() => log.add("$name.next");

  @override
  void prevPage() => log.add("$name.prev");
}

// mirrors how PdfView owns a view and hands it to the controller
class _ViewHost extends StatefulWidget {
  final ScoreFileViewController controller;
  final String name;
  final List<String> log;

  const _ViewHost({
    super.key,
    required this.controller,
    required this.name,
    required this.log,
  });

  @override
  State<_ViewHost> createState() => _ViewHostState();
}

class _ViewHostState extends State<_ViewHost> {
  late final FakeFileView _view;

  @override
  void initState() {
    super.initState();
    _view = FakeFileView(widget.name, widget.log);
    widget.log.add("attach ${widget.name}");
    widget.controller.attach(_view);
  }

  @override
  void dispose() {
    widget.log.add("detach ${widget.name}");
    widget.controller.detach(_view);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.name);
}

class _OtherHost extends StatelessWidget {
  const _OtherHost();

  @override
  Widget build(BuildContext context) => const Text("other");
}

void main() {
  test("commands are dropped while nothing is attached", () {
    final controller = ScoreFileViewController();
    controller.nextPage();
    controller.prevPage();
  });

  test("commands reach the attached view", () {
    final log = <String>[];
    final controller = ScoreFileViewController();
    controller.attach(FakeFileView("a", log));

    controller.nextPage();
    controller.prevPage();

    expect(log, ["a.next", "a.prev"]);
  });

  test("detaching the attached view stops delivery", () {
    final log = <String>[];
    final controller = ScoreFileViewController();
    final view = FakeFileView("a", log);
    controller.attach(view);
    controller.detach(view);

    controller.nextPage();

    expect(log, isEmpty);
  });

  test("a stale view cannot detach its replacement", () {
    final log = <String>[];
    final controller = ScoreFileViewController();
    final old = FakeFileView("old", log);
    final replacement = FakeFileView("new", log);

    controller.attach(old);
    controller.attach(replacement);
    controller.detach(old);

    controller.nextPage();

    expect(log, ["new.next"]);
  });

  testWidgets("replacing the host keeps page turns working", (tester) async {
    final log = <String>[];
    final controller = ScoreFileViewController();

    Widget host(String name) => MaterialApp(
      home: Stack(
        children: [
          _ViewHost(
            key: ValueKey(name),
            controller: controller,
            name: name,
            log: log,
          ),
        ],
      ),
    );

    await tester.pumpWidget(host("a"));
    controller.nextPage();
    expect(log, ["attach a", "a.next"]);

    await tester.pumpWidget(host("b"));
    controller.nextPage();

    expect(
      log,
      ["attach a", "a.next", "attach b", "detach a", "b.next"],
      reason: "the replacement attaches before the outgoing host is disposed",
    );
  });

  testWidgets("unmounting the host stops page turns", (tester) async {
    final log = <String>[];
    final controller = ScoreFileViewController();

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            _ViewHost(controller: controller, name: "a", log: log),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Stack(children: [_OtherHost()])),
    );

    controller.nextPage();

    expect(log, ["attach a", "detach a"]);
  });
}
