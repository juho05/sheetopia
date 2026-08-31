/*
 * Copyright 2025-2026 Julian Hofmann (+ Sheetopia contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:predictive_transition/predictive_transition.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/themeManager/theme_manager.dart';
import 'package:sheetopia/data/services/sharing/share_inbox.dart';
import 'package:sheetopia/providers.dart';
import 'package:sheetopia/routing/router.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/window_listener.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LogRepository logRepository = LogRepository();
  Log.init(logRepository);
  Log.info(
    "App started. Configuration: ${kReleaseMode
        ? "release"
        : kProfileMode
        ? "profile"
        : "debug"}",
  );

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.addListener(WindowCloseListener());
    windowManager.setPreventClose(true);
  }
  await FullScreen.ensureInitialized();
  await pdfrxFlutterInitialize();

  runApp(
    MultiProvider(
      providers: await createProviders(logRepository: logRepository),
      builder: (context, _) {
        return const App();
      },
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription? _shareReceiveStream;

  static const _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: PredictiveTransitionPageTransitionsBuilder(),
    },
  );

  static ThemeData _theme(Brightness brightness) => ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    ),
  ).copyWith(pageTransitionsTheme: _pageTransitions);

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(_receiveSharedFiles());
    }
  }

  Future<void> _receiveSharedFiles() async {
    final initial = await FlutterSharingIntent.instance.getInitialSharing();
    if (!mounted) return;
    _shareReceiveStream = FlutterSharingIntent.instance.getMediaStream().listen(
      _onFilesReceived,
    );
    await _onFilesReceived(initial);
  }

  Future<void> _onFilesReceived(Iterable<SharedFile> files) async {
    files = files.where((f) => f.value != null);
    if (files.isEmpty) {
      shareImport.value = const ShareImport.empty();
      return;
    }
    shareImport.value = const ShareImport.importing();
    final repo = context.read<ScoresRepository>();
    try {
      final scores = await repo.importAll(
        files.map((f) => XFile(f.value!, mimeType: f.mimeType)),
      );
      final first = scores.firstOrNull;
      if (first == null) {
        shareImport.value = const ShareImport.empty();
        return;
      }
      shareImport.value = ShareImport.ready(first.id);
      goRouter.go("/scores/${first.id}/edit");
    } on InvalidFileTypeException catch (e, st) {
      shareImport.value = const ShareImport.empty();
      Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
    } catch (e, st) {
      shareImport.value = const ShareImport.empty();
      Toast.exception(e, st: st, errorMsg: "Failed to import scores!");
    } finally {
      await cleanUpSharedFiles(files.map((f) => f.value!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp.router(
          title: 'Sheetopia',
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          themeMode: themeManager.themeMode,
          scaffoldMessengerKey: Toast.messengerKey,
          debugShowCheckedModeBanner: false,
          restorationScopeId: "app",
          routerConfig: goRouter,
        );
      },
    );
  }

  @override
  void dispose() {
    _shareReceiveStream?.cancel();
    super.dispose();
  }
}
