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
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:predictive_transition/predictive_transition.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/logger/log.dart';
import 'package:sheetopia/data/repositories/logger/log_repository.dart';
import 'package:sheetopia/data/repositories/practice/practice_repository.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/data/repositories/themeManager/theme_manager.dart';
import 'package:sheetopia/data/services/database/scores_table.dart';
import 'package:sheetopia/data/services/sharing/share_inbox.dart';
import 'package:sheetopia/providers.dart';
import 'package:sheetopia/routing/practice_resume.dart';
import 'package:sheetopia/routing/router.dart';
import 'package:sheetopia/ui/common/choice_dialog.dart';
import 'package:sheetopia/ui/common/toast.dart';
import 'package:sheetopia/ui/practice/import_exercise_scores_choice_dialog.dart';
import 'package:sheetopia/ui/score/chrome/play_session.dart';
import 'package:sheetopia/utils/full_screen.dart';
import 'package:sheetopia/utils/receive_drop.dart';
import 'package:sheetopia/utils/score_file.dart';
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

  unawaited(clearShareCache());

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      "assets/fonts/Roboto_LICENSE.txt",
    );
    yield LicenseEntryWithLineBreaks(["Roboto"], license);
  });

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.addListener(WindowCloseListener());
    windowManager.setPreventClose(true);
  }
  await AppFullScreen.ensureInitialized();
  markFullScreenReady();
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

  // bundled so that text, especially italics, renders identically on all
  // platforms instead of falling back to the very slanted Apple system italic
  static const _fontFamily = "Roboto";

  static ThemeData _theme(Brightness brightness) {
    final base = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      ),
    );
    return base.copyWith(
      pageTransitionsTheme: _pageTransitions,
      textTheme: base.textTheme.apply(fontFamily: _fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _fontFamily),
    );
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(_receiveSharedFiles());
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_resumeRunningExercise()),
    );
  }

  Future<void> _resumeRunningExercise() async {
    if (!mounted) return;
    final repo = context.read<PracticeRepository>();
    try {
      final location = await runningPracticeLocation(repo);
      if (location == null || !mounted) return;
      final current = goRouter.routerDelegate.currentConfiguration.uri.path;
      if (current != "/") {
        Log.debug("Not resuming the running exercise, already at $current");
        return;
      }
      Log.info("Reopening the exercise left running at $location");
      goRouter.go(location);
    } catch (e, st) {
      Log.warn("Failed to reopen the exercise left running", e: e, st: st);
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

  Future<BuildContext?> _waitForNavigatorContext() async {
    final key = goRouter.routerDelegate.navigatorKey;
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (key.currentContext == null && mounted) {
      if (DateTime.now().isAfter(deadline)) return null;
      await WidgetsBinding.instance.endOfFrame.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {},
      );
    }
    return key.currentContext;
  }

  Future<void> _onFilesReceived(Iterable<SharedFile> files) async {
    files = files.where((f) => f.value != null);
    if (files.isEmpty) {
      return;
    }
    final repo = context.read<ScoresRepository>();
    final xfiles = files.map((f) => XFile(f.value!, mimeType: f.mimeType));

    try {
      final navContext = await _waitForNavigatorContext();
      if (navContext == null || !navContext.mounted) {
        Log.warn("No navigator available to import shared files");
        return;
      }

      final type = await ChoiceDialog.show<ScoreType>(
        navContext,
        title: "Import as",
        options: [
          const ChoiceOption(
            value: ScoreType.score,
            title: "Score",
            subtitle: "A regular score that shows up in your library.",
          ),
          const ChoiceOption(
            value: ScoreType.exercise,
            title: "Exercise",
            subtitle: "Exercise(s) with the file(s) as scores.",
          ),
        ],
      );
      if (!navContext.mounted) {
        return;
      }

      if (type == ScoreType.score) {
        final scores = await repo.importAll(
          xfiles,
          status: ScoreStatus.needsFirstEdit,
        );
        final first = scores.firstOrNull;
        if (first == null) {
          return;
        }
        goRouter.go("/scores/import");
      } else if (type == ScoreType.exercise) {
        bool separate = false;
        if (files.length > 1) {
          final choice = await ImportExerciseScoresChoiceDialog.show(
            navContext,
          );
          if (choice == null || !navContext.mounted) {
            return;
          }
          separate = choice == ImportExerciseScoresChoice.separate;
        }
        final ok = await receiveExercise(repo, xfiles);
        if (!navContext.mounted || !ok) {
          return;
        }

        goRouter.go("/practice/exercises/create?separate=$separate");
      }
    } on InvalidFileTypeException catch (e, st) {
      Toast.exception(e, st: st, errorMsg: "Unsupported file type!");
    } catch (e, st) {
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
