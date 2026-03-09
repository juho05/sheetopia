import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:sheetopia/data/repositories/scores/scores_repository.dart';
import 'package:sheetopia/providers.dart';
import 'package:sheetopia/routing/router.dart';
import 'package:sheetopia/window_listener.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    windowManager.addListener(WindowCloseListener());
    windowManager.setPreventClose(true);
  }
  await FullScreen.ensureInitialized();
  await pdfrxFlutterInitialize();

  runApp(
    MultiProvider(
      providers: await createProviders(),
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
  late final StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _intentDataStreamSubscription = FlutterSharingIntent.instance
          .getMediaStream()
          .listen(_onFilesReceived);
      FlutterSharingIntent.instance.getInitialSharing().then(_onFilesReceived);
    }
  }

  Future<void> _onFilesReceived(Iterable<SharedFile> files) async {
    files = files.where((f) => f.value != null);
    if (files.isEmpty) {
      goRouter.go("/");
      return;
    }
    final repo = context.read<ScoresRepository>();
    final scores = await repo.importAll(files.map((f) => f.value!));
    final first = scores.firstOrNull;
    if (first == null) return;
    goRouter.go("/scores/${scores.first.id}/edit");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sheetopia',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      restorationScopeId: "app",
      routerConfig: goRouter,
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }
}
