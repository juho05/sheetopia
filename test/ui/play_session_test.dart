/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  static int builds = 0;

  late final bool inSession;

  @override
  void initState() {
    super.initState();
    builds++;
    inSession = PlaySession.isActive(context);
  }

  @override
  Widget build(BuildContext context) =>
      Text(inSession ? "in session" : "standalone");
}

void main() {
  setUp(() => _ProbeState.builds = 0);

  testWidgets("a child knows about the session while initialising", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaySession(child: _Probe())),
    );

    expect(find.text("in session"), findsOneWidget);
  });

  testWidgets("without a session a child is on its own", (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Probe()));

    expect(find.text("standalone"), findsOneWidget);
  });

  testWidgets("the chrome hides itself while the pointer rests", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaySession(child: Text("page"))),
    );
    final session = tester.state<PlaySessionState>(find.byType(PlaySession));

    expect(session.overlayVisible, isTrue);
    expect(session.backButtonVisible, isTrue);

    await tester.pump(const Duration(seconds: 3));
    expect(session.overlayVisible, isFalse);
    // the back button only follows the overlay in full screen
    expect(session.backButtonVisible, isTrue);

    await tester.tap(find.text("page"));
    await tester.pump();
    expect(session.overlayVisible, isTrue);
  });

  testWidgets("swapping the child keeps the session alive", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaySession(child: _Probe())),
    );
    final session = tester.state<PlaySessionState>(find.byType(PlaySession));

    await tester.pumpWidget(
      const MaterialApp(home: PlaySession(child: Text("other"))),
    );
    await tester.pumpWidget(
      const MaterialApp(home: PlaySession(child: _Probe())),
    );

    expect(tester.state<PlaySessionState>(find.byType(PlaySession)), session);
    expect(_ProbeState.builds, 2);
    expect(find.text("in session"), findsOneWidget);
  });
}
